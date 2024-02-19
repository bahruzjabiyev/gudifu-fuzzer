#include <pthread.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>

#include <atomic>
#include <iostream>
#include <string>

#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <arpa/inet.h>
#include "openssl/sha.h"
#include <sstream>
#include <iomanip>
#include <vector>
#include <fstream>
#include <stdlib.h>

 int fuzz_without_main(int argc, char **argv);



extern char **environ;
int random_port = 8000;

void error(const char *msg) { perror(msg); exit(0); }

bool fileExists(const std::string& name) {
  if (FILE *file = fopen(name.c_str(), "r")) {
    fclose(file);
    return true;
  } else {
    return false;
  }
}

void writeToFile(const std::string &data, const std::string &path, bool check_if_exists) {
  if (check_if_exists) {
    if (fileExists(path)) return;
  }
  FILE *out = fopen(path.c_str(), "wb");
  if (!out) return;
  const uint8_t *data_uint = reinterpret_cast<const uint8_t *>(data.c_str());
  const size_t count = fwrite(data_uint, sizeof(data_uint[0]), data.size(), out);
  fclose(out);
  if (count != data.size()) error(": an error prevented the completion of the writing.");
}

std::string readFile(const std::string& name) {
  std::ifstream t(name);
  std::stringstream buffer;
  buffer << t.rdbuf();
  return buffer.str();
}

bool replace(std::string& str, const std::string& from, const std::string& to) {
  size_t start_pos = str.find(from);
  if(start_pos == std::string::npos)
    return false;
  str.replace(start_pos, from.length(), to);
  return true;
}

std::string lower(std::string& str) {
  std::string result_str = str;
  for(auto& c : result_str) {
    c = tolower(c);
  }

  return result_str;
}

void addHash(std::string& request, const std::string& hash) {
  std::string request_lower = lower(request);
  // If request has no body, add hash as a body
  if (request_lower.find("\r\n\r\n") + 4 == request_lower.length()) {
    std::string body = "hash-" + hash;

    // Remove existing content-length headers in input, makes no sense anyway
    // without a body
    int pos_cl = 0;
    while(true) {
      request_lower = lower(request);
      pos_cl = request_lower.find("content-length");
      if (pos_cl == -1) break;
      replace(request, request.substr(pos_cl, 14), "invalid-header");
    }

    // Remove existing transfer-encoding headers in input, makes no sense anyway
    // without a body
    int pos_te = 0;
    while(true) {
      request_lower = lower(request);
      pos_te = request_lower.find("transfer-encoding");
      if (pos_te == -1) break;
      replace(request, request.substr(pos_te, 17), "invalid-header");
    }

    // Add new content-length header with the value of the new body which
    // contains the hash
    replace(request, "\r\n\r\n", "\r\ncontent-length: 45\r\n\r\n" + body);
  } else { // just add in the end of headers block
    replace(request, "\r\n\r\n", "\r\nvia: hash-" + hash + "\r\n\r\n");
  }
}

std::string sha1ToString(uint8_t sha1_hash[SHA_DIGEST_LENGTH]) {
  std::stringstream ss;
  for (int i = 0; i < SHA_DIGEST_LENGTH; i++)
    ss << std::hex << std::setfill('0') << std::setw(2) << static_cast<unsigned>(sha1_hash[i]);
  return ss.str();
}

// A function called by a create thread that will run server inside the single thread
void* runServerThread(void*) {
  std::string random_port_str = std::to_string(random_port);
  //std::cout << "random port is: " << random_port_str << "\n";
  std::string conf_template_name = "/src/envoy.yaml";
  std::string ext = ".yaml";
  std::string conf_content = readFile(conf_template_name);
  // Replacing _PORT_ with random port number
  int pos_port;
  while(true) {
    pos_port = conf_content.find("_PORT_");
    if (pos_port == -1) break;
    replace(conf_content, "_PORT_", random_port_str);
  }

  //std::cout << "new conf content is: " << conf_content << "\n";
  std::string conf_file_name_str = conf_template_name+random_port_str+ext;
  writeToFile(conf_content, conf_file_name_str, false);
  const char *conf_file_name = conf_file_name_str.c_str();

  char *my_argv[] = {(char*)"/tmp/envoy", (char*)"-c", (char*)conf_file_name, (char*)"--base-id", (char*)(const char*)random_port_str.c_str(), NULL};
  const int my_argc = std::end(my_argv) - std::begin(my_argv) - 1;

  // This will run the server in a single process mode, and in our case in a single thread.
  fuzz_without_main(my_argc, my_argv);

  return NULL;
}

std::string sendRequest(const std::string& req, const std::string& request_sha_hash) {
  int sockfd, bytes, sent;

  std::string request = req;
  addHash(request, request_sha_hash);

  //std::cout << "here is the request: " << request << "\n";

  /* create the socket */
  sockfd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (sockfd < 0) error("ERROR opening socket");

  /* fill in the structure */
  struct sockaddr_in client;
  memset(&client,0,sizeof(client));
  client.sin_family = AF_INET;
  client.sin_port = htons(random_port);
  client.sin_addr.s_addr = inet_addr("127.0.0.1");
  int clientsockfd = socket(AF_INET, SOCK_STREAM, 0);

  std::string conn_err = "000";
  /* connect the socket */
  if (connect(clientsockfd,(struct sockaddr *)&client,sizeof(client)) < 0)
    return conn_err;

  /* send the request */
  const char* hashed_message = request.c_str();
  int hashed_message_len = (int)request.length();
  sent = 0;
  do {
    bytes = write(clientsockfd,hashed_message+sent,hashed_message_len-sent);
    if (bytes < 0)
      error("ERROR writing message to socket");
    if (bytes == 0)
      break;
    sent+=bytes;
  } while (sent < hashed_message_len);

  char recvBuff[1024];
  std::string response="";
  int n=0;

  struct timeval timeout;
  timeout.tv_sec = 0;
  timeout.tv_usec = 50000;
  setsockopt(clientsockfd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));

  while ( (n = read(clientsockfd, recvBuff, sizeof(recvBuff)-1)) > 0)
  {
    recvBuff[n] = 0;
    response = response + std::string(recvBuff);
    break;
  }
  //std::cout << "here is the response: " << std::string(response) << "\n";


  //std::string bad_response = "HTTP/1.1 555";
  //n = read(clientsockfd, recvBuff, sizeof(recvBuff)-1);
  //if (n <= 0) return bad_response;
  //response = std::string(recvBuff); 

  /* close the socket */
  close(clientsockfd);

  return response;
}

void setRandomPort(){
   random_port = 2000 + getpid()%63000;
}

bool startServer(){
  //setRandomPort();
  pthread_t server_thread;
  pthread_create(&server_thread, NULL, &runServerThread, NULL);
  sleep(1);
  for (int i=0; i<100; i++) {sendRequest("GET / HTTP/1.1\r\nHost:localhost\r\n\r\n", "efgh");}
  return true;
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t data_len) {
  static bool server_started = startServer();
  if(!server_started) {
    error("server not running");
  }

  unsigned char request_sha[SHA_DIGEST_LENGTH];
  SHA1(data, data_len, request_sha);
  std::string request_sha_str = sha1ToString(request_sha);
  if (request_sha_str == "abcd") std::cout << "here is the request hash: " << request_sha_str << "\n";

  return 0;
}
