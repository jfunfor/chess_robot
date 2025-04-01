import redis


class RedisConnector:
    def __init__(self, host='localhost', port=6379, db=0):
        self.host = host
        self.port = port
        self.db = db
        self.client = None

    def connect(self):
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
        if self.client:
            self.client.close()
            self.client = None

    def execute(self, command, *args):
        if not self.client:
            self.connect()
        return self.client.execute_command(command, *args)
