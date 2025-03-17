import socket

def handle_client(client_socket, address):
    print(f"Подключение от {address}")

    while True:
        data = client_socket.recv(1024).decode('utf-8')
        if not data:
            break

        print(f"Получено сообщение: {data}")

        response = input("Введите ответ: ")

        client_socket.send(response.encode('utf-8'))

    client_socket.close()
    print(f"Клиент {address} отключился")

def start_server():
    host = '127.0.0.1'
    port = 12345

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    server_socket.bind((host, port))

    server_socket.listen(1)
    print(f"Сервер запущен на {host}:{port}")

    while True:
        client_socket, address = server_socket.accept()
        print(f"Новое подключение от {address}")

        handle_client(client_socket, address)

if __name__ == "__main__":
    start_server()