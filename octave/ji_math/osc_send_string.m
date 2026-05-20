function osc_send_string(host, port, address, val)
% OSC_SEND_STRING  minimal OSC sender for a single string argument
%
% osc_send_string('127.0.0.1', 57120, '/anceps/riff', '7/4 3/2 5/4')

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
    
    % 2. Pack Typetag (",s" null terminated, 4-byte padded)
    type_bytes = uint8(',s');
    type_bytes(end+1) = 0;
    while mod(numel(type_bytes), 4) ~= 0
      type_bytes(end+1) = 0;
    end
    
    % 3. Pack String Value (null terminated, 4-byte padded)
    val_bytes = uint8(val);
    val_bytes(end+1) = 0;
    while mod(numel(val_bytes), 4) ~= 0
      val_bytes(end+1) = 0;
    end
    
    % 4. Combine and send
    packet = [addr_bytes, type_bytes, val_bytes];
    sendto(sock, packet, dest);
    disconnect(sock);
  catch
    % fail silently
  end
end
