#!/usr/bin/env python3
"""
modbus_server_sim.py — Simulated Modbus TCP device for Cyber-Lab-v2 ot_zone.

Represents a minimal simulated industrial asset with a few holding
registers, standing in for something like a tank level, a flow rate,
and a valve status. This gives the IT/OT segmentation chain a real
service to protect rather than an empty instance.

Listens on 0.0.0.0:502 (standard Modbus TCP port). Reachable only from
idmz, per ot_zone_sg — this script does not enforce that itself, the
security group is the actual control. This script is intentionally
"insecure" by design (no auth, no encryption) because that is exactly
what real-world Modbus TCP looks like — the protocol has none built in.
The network segmentation IS the security control, not the application.
"""

from pymodbus.datastore import ModbusSequentialDataBlock, ModbusSlaveContext, ModbusServerContext
from pymodbus.server import StartTcpServer
from pymodbus.device import ModbusDeviceIdentification
import logging

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

# Holding registers (function code 03/06/16):
#   Index 0 is an unused placeholder register. Testing confirmed this
#   pymodbus 3.8.6 server consistently returns data starting one
#   register after the requested address (a known addressing quirk in
#   this version — the zero_mode parameter that fixes it in older
#   pymodbus APIs no longer exists in 3.x). Padding with one leading
#   placeholder keeps real data aligned with what clients actually
#   receive, without depending on internal library behavior.
#   Index 1: simulated tank level (0-100, percent)
#   Index 2: simulated flow rate (L/min)
#   Index 3: simulated valve status (0 = closed, 1 = open)
initial_values = [0, 42, 118, 1] + [0] * 6  # pad to 10 registers total

store = ModbusSlaveContext(
    hr=ModbusSequentialDataBlock(0, initial_values)
)
context = ModbusServerContext(slaves=store, single=True)

identity = ModbusDeviceIdentification()
identity.VendorName = "Cyber-Lab-v2"
identity.ProductCode = "SIM-OT-01"
identity.VendorUrl = "https://github.com/Maxilyte/Cyber-Lab-v2"
identity.ProductName = "Simulated OT Device"
identity.ModelName = "ot_zone modbus sim"
identity.MajorMinorRevision = "1.0"

if __name__ == "__main__":
    log.info("Starting simulated Modbus TCP server on 0.0.0.0:502")
    log.info("Holding registers: [tank_level, flow_rate, valve_status, ...padding]")
    StartTcpServer(context=context, identity=identity, address=("0.0.0.0", 502))
