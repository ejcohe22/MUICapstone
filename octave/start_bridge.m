% start_bridge.m
% starts the OSC receiver with the bridge_to_inference callback

printf('starting anceps bridge...\n');
osc_receive('callback', @bridge_to_inference);
