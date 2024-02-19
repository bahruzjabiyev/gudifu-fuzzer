import socket
import threading
import re
import sys
import time

class Listener():
  def __init__(self, show_conn_status = False):
    self.request_list = []
    self.batch_num = 0
    self.lock = threading.Lock()
    self.show_conn_status = show_conn_status

  def handle_connection(self, conn):
    data = b''
    conn_status = b'NO_INFO'
    start_time = None
    duration = b''
    try:
      #conn.settimeout(0.025)
      conn.settimeout(0.25) #slowing down 10 times
      while True:
        try:
          conn_data = conn.recv(2048)
          if not conn_data:
            end_time = time.time() # get the time when FIN is received
            if start_time:
              duration = "{}".format(end_time - start_time).encode()
              conn_status = duration + b'_FIN_RECEIVED'
            else:
              conn_status = b'DIRECT_FIN_RECEIVED'
            break
          else:
            if data == b'': # get the time when data first received
              start_time = time.time()
            data += conn_data
        except socket.timeout:
          conn_status = b'RECV_TIMEOUT'
          break

      if self.show_conn_status:
        data = conn_status + b';' + data
      with self.lock:
        hash_values = re.findall(b'(?<=hash-)[a-f0-9]{40}', data)
        if hash_values:
          filename = hash_values[0].decode()
          with open("/4/4.66/logs/{}_{}".format(sys.argv[1], filename), 'wb') as outfile:
            outfile.write(data)

      response = b"HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n"
      conn.sendall(response)
      conn.close()
    except Exception as exception:
      pass
      #print("exception {} when received {}.".format(exception, data), file=sys.stderr)

  def _listen(self):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('', 8001))
    s.listen()
    while True:
      try:
        conn, addr = s.accept()
        thread = threading.Thread(target=self.handle_connection, args=(conn,))
        thread.start()
      except Exception as exception:
        pass
        #print("exception {} when addr is {}.".format(exception, addr), file=sys.stderr)

    s.close()

_listener = Listener()
_listener._listen()
