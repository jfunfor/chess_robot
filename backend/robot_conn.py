import socket
import os

from dotenv import load_dotenv
load_dotenv()

class RobotConnector:
    def __init__(self):
        self.host = os.getenv("ROBOT_HOST", "localhost")
        self.port = int(os.getenv("ROBOT_PORT", 12345))
        self.socket = None

    def connect(self):
        """Устанавливает TCP-соединение с роботом."""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((self.host, self.port))
            print(f"Connected to robot at {self.host}:{self.port}")
        except ConnectionRefusedError:
            print(f"Connection to robot at {self.host}:{self.port} refused.")
            exit(1)

    def send_and_receive(self, message):
        """
        Отправляет команду роботу и получает ответ.
        
        Параметры:
            message (str): команда для отправки
        
        Возвращает:
            str | None: ответ робота или None при ошибке
        """
        try:
            self.socket.sendall(message.encode())
            response = self.socket.recv(1024).decode()
            return response
        except Exception as e:
            print(f"Error communicating with robot: {e}")
            return None

    def close(self):
        """Закрывает соединение с роботом."""
        if self.socket:
            self.socket.close()
            print("Connection to robot closed")
