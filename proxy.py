import socket, threading, select, sys

# --- Config ---
# Listen on Port 80 (Standard WS)
LISTENING_PORT = 80
# Forward to Dropbear/SSH (Local Port 109 or 22)
SSH_PORT = 109 
# Response Header
PASS = b''

# --- Logic ---
def handle_client(client_socket):
    try:
        request = client_socket.recv(1024).decode('utf-8', errors='ignore')
        # Check if it's a WebSocket Upgrade Request
        if "Upgrade: websocket" in request:
            # Connect to SSH
            server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_socket.connect(('127.0.0.1', SSH_PORT))
            
            # Send Success Response to Client
            response = "HTTP/1.1 101 Switching Protocols\r\n" \
                       "Upgrade: websocket\r\n" \
                       "Connection: Upgrade\r\n\r\n"
            client_socket.send(response.encode('utf-8'))
            
            # Start Forwarding
            while True:
                r, w, x = select.select([client_socket, server_socket], [], [])
                if client_socket in r:
                    data = client_socket.recv(4096)
                    if not data: break
                    server_socket.send(data)
                if server_socket in r:
                    data = server_socket.recv(4096)
                    if not data: break
                    client_socket.send(data)
        else:
            # If not WS, standard HTTP behavior (or close)
            client_socket.send("HTTP/1.1 200 OK\r\n\r\n".encode('utf-8'))
            client_socket.close()
            
    except Exception as e:
        pass
    finally:
        client_socket.close()

def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(('0.0.0.0', LISTENING_PORT))
    server.listen(100)
    print(f"[*] Proxy listening on port {LISTENING_PORT}")
    
    while True:
        client_sock, addr = server.accept()
        client_handler = threading.Thread(target=handle_client, args=(client_sock,))
        client_handler.start()

if __name__ == "__main__":
    start_server()