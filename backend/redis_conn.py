import redis
import os

from dotenv import load_dotenv
load_dotenv()

class RedisConnector:
    def __init__(self, db=0):
        self.host = os.getenv("REDIS_HOST", "localhost")
        self.port = int(os.getenv("REDIS_PORT", 6379))
        self.db = db
        self.client = None

    def connect(self):
        """Устанавливает соединение с Redis-сервером."""
        if not self.client:
            try:
                self.client = redis.Redis(
                    host=self.host,
                    port=self.port,
                    db=self.db
                )
                self.client.ping()
                print(f"Connected to Redis db at {self.host}:{self.port}")
            except Exception as e:
                print(f"Ошибка подключения к базе данных: {e}")
                exit(1)

    def disconnect(self):
        """Закрывает соединение с Redis."""
        if self.client:
            self.client.close()
            self.client = None

    def execute(self, command, *args):
        """
        Выполняет команду Redis.
        
        Параметры:
            command (str): название команды (например, "SET")
            *args: аргументы команды
        
        Возвращает:
            Any: результат выполнения команды
        """
        if not self.client:
            self.connect()
        return self.client.execute_command(command, *args)
