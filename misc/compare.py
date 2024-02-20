from sys import argv
import glob
from multiprocessing import Process, Queue
from collections import defaultdict

class Comparer:
  def __init__(self, server_names, target_dir="/logs/", output_format="json"):
    if not target_dir.endswith("/"):
      print("The directory path should have '/' in the end.")
      exit()
    self.sample_size = 10000
    self.target_dir = target_dir
    self.server_names = server_names
    self.output_format = output_format

  def getRequestBody(self, request):
    return b'\r\n\r\n'.join(request.split(b'\r\n\r\n')[1:])

  def compare(self, _hash, individual=False):
    """
    Takes a single hash. Based on this hash
    it gets the input request and the corresponding
    forwarded requests. Returns the list of
    additions, deletions and modifications done
    by each forwarded request on the input request.

    :param _hash: the value based on which the
    comparison happens.
    :param individual: enables comparison for
    an individual hash without a need for the
    comparison of the whole directory.
    """
    try:
      with open(f'{self.target_dir}input_{_hash}', 'rb') as inputf:
        input_request = inputf.read().lower()
    except FileNotFoundError:
      return []
    if not input_request:
      return []
    result = {}
    if individual:
      hash_server_names = [filename.split('/')[-1].split('_')[0] for filename in glob.glob(f'{self.target_dir}*_{_hash}')]
    else:
      hash_server_names = [filename.split('/')[-1].split('_')[0] for filename in self.hash_files[_hash]]
    #hash_server_names.remove("input")
    hash_server_names = list(set(hash_server_names) - (set(hash_server_names) - set(self.server_names)))
    if not hash_server_names:
      return []

    for server_name in hash_server_names:
      result[server_name] = {b'additions': [], b'deletions': [], b'modifications': [], b'line-modifications': [], b'body-modifications': []}
      with open(f'{self.target_dir}{server_name}_{_hash}', 'rb') as inputf:
        result[server_name]["request"] = inputf.read().lower()
      with open(f'{self.target_dir}{server_name}_{_hash}', 'rb') as inputf:
        result[server_name]["request"] = inputf.read().lower()

    input_headers = input_request.split(b'\r\n\r\n')[0].split(b'\r\n')
    input_request_body = b''
    if b'\r\n\r\n' in input_request:
      input_request_body = self.getRequestBody(input_request)

    for server_name in hash_server_names:

      headers_block = result[server_name]['request'].split(b'\r\n\r\n')[0]
      request_body = b''
      if b'\r\n\r\n' in result[server_name]['request']:
        request_body = self.getRequestBody(result[server_name]['request'])

      for linenum, line in enumerate(headers_block.split(b'\r\n')):
        if line in input_headers:
          continue
        if linenum == 0: #request line
          #result[server_name][b"line-modifications"].append(input_headers[0] + b'----' + line)
          self.addModification(result[server_name][b"line-modifications"], "line-modifications", input_headers[0], line)
        else:
          if b':' not in line:
            result[server_name][b"additions"].append(line)
          else:
            loc = line.find(b':')
            header_name = line[:loc]
            header_value = line[loc:]
            # get the whole header from the input request using header name
            headers = [line for line in input_headers if line.startswith(header_name + b':')]
            if len(headers) == 0:
              result[server_name][b"additions"].append(line)
            elif len(headers) == 1:
              #result[server_name][b"modifications"].append(headers[0] + b'----' + line)
              self.addModification(result[server_name][b"modifications"], "modifications", headers[0], line)
            else:
              result[server_name][b"modifications"].append(b'----'.join(headers) + b'====' + line)

      for line in input_headers:
        if line in headers_block:
          continue
        # see if any modification contains the line
        if True not in [line in modification for modification in result[server_name][b"modifications"]]:
          result[server_name][b"deletions"].append(line)

      if request_body != input_request_body:
        self.addModification(result[server_name][b"body-modifications"], "body-modifications", input_request_body, request_body)
        #result[server_name][b"modifications"].append(input_request_body + b'----' + request_body)

    if self.output_format == "awkable":
      output = []
      for server_name in result:
        for operation in [b"additions", b"deletions", b"modifications", b"line-modifications", b"body-modifications"]:
          for item in result[server_name][operation]:
            #output.append(f'{operation} ::::: {_hash} ::::: {server_name} ::::: {item}')
            output.append(operation + b' ::::: ' + _hash.encode() + b' ::::: ' + server_name.encode() + b' ::::: ' + item)
      return output

    return result

  def addModification(self, arr, modification_type, _from, _to):
    ignorable = False
    if modification_type == "modifications":
      if (_to.replace(b": ", b":",1) == _from):
        ignorable = True
    elif modification_type == "line-modifications":
      if (_from.replace(b"http/1.1", b"http/1.0", 1) == _to): 
        ignorable = True
    elif modification_type == "body-modifications":
      if (_from == b'' and _to.startswith(b'hash-')):
        ignorable = True
    ignorable=False #delete
    if not ignorable:
      arr.append(_from + b'----' + _to)

  def processHashes(self, hashes, quot):
    """
    Takes the list of hashes and returns
    a the comparison results for them.

    :param hashes: the list of hash values
    :param quot: this is a queue shared by
    multiple processes.
    """
    result = []
    for _hash in hashes:
      result.append(self.compare(_hash))

    quot.put(result)


  def compareDir(self):
    """
    Does a comparison on the whole directory and
    return the results.
    """
    self.hash_files = {}
    for filename in glob.glob(f'{self.target_dir}*_*'):
      _hash = filename.split('_')[1]
      if _hash not in self.hash_files:
        self.hash_files[_hash] = [filename]
      else:
        self.hash_files[_hash].append(filename)

    #print(self.hash_files)

    #print(["showme", self.hash_files["f4c7093818b7d5ec9c333d7e40d13a57e99b1f01"]])
    forwarded_hashes = list(self.hash_files.keys()) # delete
    num_procs = 192
    forwarded_hashes_splitted = [[forwarded_hashes[i] for i in list(range(i, len(forwarded_hashes), num_procs))] for i in range(num_procs)]
    #print(forwarded_hashes_splitted)
    quot = Queue()
    processes = [Process(target=self.processHashes, args=(forwarded_hashes_splitted[i], quot)) for i in range(num_procs)]

    for i, proc in enumerate(processes):
      proc.start()

    result = [quot.get() for p in processes]

    for i, proc in enumerate(processes):
      proc.join()

    self.results = [ent for sublist in result for ent in sublist]

  def processResults(self):
    self.compareDir()
    self.hashes = defaultdict(list)
    for result in self.results: #awkable format
      for line in result:
        #print(line)
        self.hashes[line.split(b' ::::: ')[1]].append(line.split(b' ::::: '))

  def getFrequencies(self):
    self.freqs = {}
    for server in self.server_names:
      self.freqs[server] = defaultdict(int)
    for result in self.results[:self.sample_size]:
      for line in result:
        _type, _hash, _server, _action = line.split(b" ::::: ")
        self.freqs[_server.decode()][_action] += 1
     
  def bucketize(self, action_type):
    self.processResults()
    self.getFrequencies()
    #print(self.hashes)
    for _hash, list_columns in self.hashes.items():
      relevant_servers = set([columns[2] for columns in list_columns])
      if len(relevant_servers) <= 1:
        continue
      temp = defaultdict(list)
      for columns in list_columns:
        if columns[0] != action_type:
          continue
        if columns[2].decode() not in [item[0] for item in temp[columns[3]]]:
          temp[columns[3]].append((columns[2].decode(), f'{self.freqs[columns[2].decode()][columns[3]]}/{self.sample_size}'))

      for key in temp:
        current_servers = set([item[0].encode() for item in temp[key]])
        for server in (relevant_servers - current_servers):
          temp[key].append((server.decode(), '-/-'))

      for key, value in temp.items():
        print(str(value).replace("'apache', '", 'Ā:').replace("'nginx', '", 'Ń:').replace("'ats', '", 'Ť:').replace("'haproxy', '", 'Ĥ:').replace("'h2o', '", 'Ŵ:').replace("'envoy', '", 'Ê:').replace("/10000'", ";").replace("/-'", ";"), "----", key, "----", _hash)

  def writeOutput(self):
    """
    Writes the comparison results to stdout
    in the specified format (e.g., awkable).
    """
    #result = self.compareDir()
    if self.output_format == "json":
      for item in self.results:
        print(item)
    elif self.output_format == "awkable":
      for item in self.results:
        for i in item:
          print(i)

c = Comparer(server_names=['apache', 'nginx', 'h2o', 'ats', 'haproxy', 'envoy'], target_dir=argv[1], output_format="awkable")
#print(c.compare(argv[2], individual=True))
#c.writeOutput()
#{b'additions', b'deletions', b'modifications', b'line-modifications', b'body-modifications'}
c.bucketize(argv[2].encode())
