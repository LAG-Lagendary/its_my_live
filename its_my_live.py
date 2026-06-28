#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import time
import signal
import logging
import socket
from logging.handlers import RotatingFileHandler
import pika
import psutil

# Настройка путей
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(BASE_DIR, "its_my_live.log")

# Настройка безопасного ротируемого логирования (максимум 5 МБ на файл, храним до 3 копий)
logger = logging.getLogger("ItsMyLive")
logger.setLevel(logging.INFO)
formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")

file_handler = RotatingFileHandler(LOG_FILE, maxBytes=5 * 1024 * 1024, backupCount=3, encoding="utf-8")
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)

# Также дублируем логирование в стандартный вывод для системного журнала systemd (journalctl)
stream_handler = logging.StreamHandler(sys.stdout)
stream_handler.setFormatter(formatter)
logger.addHandler(stream_handler)


class ItsMyLiveDaemon:
    """
    Основной управляющий класс фоновой службы.
    Обеспечивает непрерывный мониторинг системных ресурсов и отправку метрик в RabbitMQ.
    """
    def __init__(self, rabbit_host="localhost", queue_name="its_my_live_metrics"):
        self.running = True
        self.rabbit_host = rabbit_host
        self.queue_name = queue_name
        self.connection = None
        self.channel = None
        self.hostname = socket.gethostname()

        # Регистрация системных сигналов для корректного и безопасного завершения работы
        signal.signal(signal.SIGINT, self.handle_shutdown)
        signal.signal(signal.SIGTERM, self.handle_shutdown)

    def handle_shutdown(self, signum, frame):
        """Обработчик системных сигналов завершения"""
        logger.info(f"Получен сигнал остановки ({signum}). Завершаем работу демона...")
        self.running = False

    def connect_to_rabbit(self):
        """
        Установка соединения с RabbitMQ с механизмом повторных попыток (Reconnection Loop)
        и защитой от падения при недоступности брокера.
        """
        attempts = 0
        max_attempts = 5
        backoff = 2

        while self.running and attempts < max_attempts:
            try:
                logger.info(f"Попытка подключения к RabbitMQ ({self.rabbit_host})...")
                self.connection = pika.BlockingConnection(
                    pika.ConnectionParameters(host=self.rabbit_host, connection_attempts=3, retry_delay=2)
                )
                self.channel = self.connection.channel()
                # Создаем устойчивую (durable) очередь для метрик
                self.channel.queue_declare(queue=self.queue_name, durable=True)
                logger.info("Успешно подключено к RabbitMQ!")
                return True
            except pika.exceptions.AMQPConnectionError as e:
                attempts += 1
                logger.warning(f"Не удалось подключиться к RabbitMQ ({e}). Повтор через {backoff} сек...")
                time.sleep(backoff)
                backoff = min(backoff * 2, 30)  # Экспоненциальный бэкафф
            except Exception as e:
                logger.error(f"Непредвиденная ошибка при подключении к RabbitMQ: {e}")
                break

        logger.error("Превышено количество попыток подключения к RabbitMQ. Демон продолжит работу в автономном режиме.")
        return False

    def get_system_metrics(self):
        """Сбор базовых метрик системы без перегрузки CPU"""
        try:
            cpu_usage = psutil.cpu_percent(interval=None)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            load_avg = os.getloadavg() if hasattr(os, "getloadavg") else (0.0, 0.0, 0.0)

            # Формируем JSON-подобную структуру
            metrics = (
                f'{{"host": "{self.hostname}", '
                f'"cpu_percent": {cpu_usage}, '
                f'"memory_percent": {memory.percent}, '
                f'"disk_percent": {disk.percent}, '
                f'"load_avg_1m": {load_avg[0]}}}'
            )
            return metrics
        except Exception as e:
            logger.error(f"Ошибка при сборе системных метрик: {e}")
            return None

    def publish_metrics(self, payload):
        """Безопасная публикация сообщения в очередь RabbitMQ"""
        if not self.channel or self.connection.is_closed:
            logger.warning("Соединение с RabbitMQ потеряно. Попытка переподключения...")
            if not self.connect_to_rabbit():
                return False

        try:
            self.channel.basic_publish(
                exchange="",
                routing_key=self.queue_name,
                body=payload,
                properties=pika.BasicProperties(
                    delivery_mode=2,  # Делаем сообщение стойким (сохраняется на диск)
                    content_type="application/json"
                )
            )
            logger.info(f"Метрики успешно отправлены в RabbitMQ: {payload}")
            return True
        except Exception as e:
            logger.error(f"Не удалось отправить сообщение в RabbitMQ: {e}")
            return False

    def start(self):
        """Основной рабочий цикл службы"""
        logger.info("Служба its_my_live запущена и инициализирована.")

        # Первоначальное подключение к RabbitMQ
        self.connect_to_rabbit()

        while self.running:
            metrics = self.get_system_metrics()
            if metrics:
                # Пытаемся отправить данные в RabbitMQ
                self.publish_metrics(metrics)

            # Безопасное ожидание следующей итерации (60 секунд)
            # Разбиваем ожидание на мелкие отрезки, чтобы моментально реагировать на SIGTERM/SIGINT
            for _ in range(60):
                if not self.running:
                    break
                time.sleep(1)

        # Корректное закрытие всех соединений перед выходом
        self.cleanup()

    def cleanup(self):
        """Освобождение системных ресурсов и закрытие сетевых сокетов"""
        logger.info("Освобождение занятых системных ресурсов...")
        try:
            if self.connection and not self.connection.is_closed:
                self.connection.close()
                logger.info("Соединение с RabbitMQ успешно закрыто.")
        except Exception as e:
            logger.error(f"Ошибка при закрытии соединения RabbitMQ: {e}")
        logger.info("Демон завершил работу.")


if __name__ == "__main__":
    # Проверка прав (демон может работать как от обычного пользователя, так и от root)
    daemon = ItsMyLiveDaemon()
    daemon.start()