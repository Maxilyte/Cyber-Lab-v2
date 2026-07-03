#!/usr/bin/env python3
"""
modbus_client_test.py — Modbus TCP client for Cyber-Lab-v2.

Run from idmz to read the simulated holding registers on ot_zone.
Proves the IT/OT segmentation chain permits legitimate Modbus traffic
through the one path designed for it (idmz -> ot_zone, port 502),
while every other path remains blocked by the security group chain.
"""

from pymodbus.client import ModbusTcpClient

OT_ZONE_IP = "10.0.20.135"
MODBUS_PORT = 502

client = ModbusTcpClient(OT_ZONE_IP, port=MODBUS_PORT)

if client.connect():
    print(f"Connected to simulated OT device at {OT_ZONE_IP}:{MODBUS_PORT}")

    result = client.read_holding_registers(address=0, count=3)

    if result.isError():
        print(f"Modbus error: {result}")
    else:
        tank_level, flow_rate, valve_status = result.registers
        print(f"  Tank level:   {tank_level}%")
        print(f"  Flow rate:    {flow_rate} L/min")
        print(f"  Valve status: {'OPEN' if valve_status == 1 else 'CLOSED'}")

    client.close()
else:
    print(f"Failed to connect to {OT_ZONE_IP}:{MODBUS_PORT}")
