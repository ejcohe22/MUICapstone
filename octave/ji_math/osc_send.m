function osc_send(host, port, address, val)
% OSC_SEND  minimal OSC sender for a single float argument
%
% osc_send('127.0.0.1', 57120, '/visual/patina', 0.5)

  try
    pkg load sockets;
    sock = socket(AF_INET, SOCK_DGRAM, 0);
    dest = struct('addr', host, 'port', port);
    
    % 1. Pack Address (null terminated, 4-byte padded)
    addr_bytes = uint8(address);
    addr_bytes(end+1) = 0;
    while mod(numel(addr_bytes), 4) ~= 0
      addr_bytes(end+1) = 0;
    end
    
    % 2. Pack Typetag (",f" null terminated, 4-byte padded)
    type_bytes = uint8(',f');
    type_bytes(end+1) = 0;
    while mod(numel(type_bytes), 4) ~= 0
      type_bytes(end+1) = 0;
    end
    
    % 3. Pack Float (32-bit big endian)
    f_val = single(val);
    val_bytes = typecast(f_val, 'uint8');
    % Octave is usually little endian, OSC is big endian
    [~, ~, endian] = computer();
    if endian == 'L'
      val_bytes = val_bytes([4 3 2 1]);
    end
    
    % 4. Combine and send
    packet = [addr_bytes, type_bytes, val_bytes];
    sendto(sock, packet, dest);
    disconnect(sock);
  catch
    % fail silently to avoid breaking the main loop if SC is down
  end
end
