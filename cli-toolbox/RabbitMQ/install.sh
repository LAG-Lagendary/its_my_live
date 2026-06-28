#!/usr/bin/env python3
import os
import sys
import time
import logging
import subprocess
import pika
from dotenv import load_dotenv

# Настройка системного логирования в выделенный каталог
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("/var/log/its_my_live/agent.log"),
        logging.StreamHandler(sys.stdout)
    ]
)

# Загрузка переменных окружения
load_dotenv()
RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "localhost")
RABBITMQ_USER = os.getenv("RABBITMQ_USER", "guest")
RABBITMQ_PASS = os.getenv("RABBITMQ_PASS", "guest")
QUEUE_NAME = os.getenv("QUEUE_NAME", "live_tasks")

def execute_safe_command(command_payload):
    """
    Выполнение строго определенного перечня безопасных команд.
    Исключает произвольное выполнение системного кода, предотвращая сбои ОС.
    """
    allowed_commands = {
        "status": ["systemctl", "status", "rabbitmq-server"],
        "disk": ["df", "-h"],
        "memory": ["free", "-m"]
    }

    if command_payload not in allowed_commands:
        logging.warning(f"Заблокирована попытка выполнения недопустимой команды: {command_payload}")
        return "Ошибка: Команда отклонена политикой безопасности."

    try:
        result = subprocess.run(
            allowed_commands[command_payload],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=10
        )
        return result.stdout if result.returncode == 0 else result.stderr
    except subprocess.TimeoutExpired:
        logging.error(f"Превышено время ожидания (timeout) для команды: {command_payload}")
        return "Ошибка: Превышено время ожидания операции."
    except Exception as e:
        logging.error(f"Критический сбой выполнения: {str(e)}")
        return f"Системная ошибка: {str(e)}"

def message_callback(ch, method, properties, body):
    """
    Обработчик входящих сообщений из очереди.
    """
    try:
        command = body.decode('utf-8')
        logging.info(f"Получена системная задача: {command}")
        response = execute_safe_command(command)
        logging.info(f"Результат выполнения операции: {response.strip()}")
        ch.basic_ack(delivery_tag=method.delivery_tag)
    except Exception as e:
        logging.error(f"Ошибка при обработке сообщения: {str(e)}")
        ch.basic_reject(delivery_tag=method.delivery_tag, requeue=False)

def main():
    logging.info("Инициализация службы агента its_my_live...")

    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    connection_params = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        credentials=credentials,
        heartbeat=600,
        blocked_connection_timeout=300
    )

    while True:
        try:
            connection = pika.BlockingConnection(connection_params)
            channel = connection.channel()
            channel.queue_declare(queue=QUEUE_NAME, durable=True)
            channel.basic_qos(prefetch_count=1)
            channel.basic_consume(queue=QUEUE_NAME, on_message_callback=message_callback)

            logging.info("Соединение с RabbitMQ установлено. Ожидание задач...")
            channel.start_consuming()

        except pika.exceptions.AMQPConnectionError:
            logging.warning("Сбой подключения к RabbitMQ. Повторная попытка через 10 секунд...")
            time.sleep(10)
        except KeyboardInterrupt:
            logging.info("Работа агента завершена пользователем.")
            break
        except Exception as e:
            logging.critical(f"Непредвиденная системная ошибка: {str(e)}")
            time.sleep(5)

if __name__ == "__main__":
    main()