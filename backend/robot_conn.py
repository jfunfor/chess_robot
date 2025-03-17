import socket


class RobotConnector:
    def __init__(self, host='localhost', port=12345):
        self.host = host
        self.port = port
        self.socket = None

    def connect(self):
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((self.host, self.port))
            print(f"Connected to robot at {self.host}:{self.port}")
        except ConnectionRefusedError:
            print(f"Connection to robot at {self.host}:{self.port} refused.")
            exit(1)

    def send_and_receive(self, message):
        try:
            self.socket.sendall(message.encode())
            response = self.socket.recv(1024).decode()
            return response
        except Exception as e:
            print(f"Error communicating with robot: {e}")
            return None

    def close(self):
        if self.socket:
            self.socket.close()
            print("Connection to robot closed")