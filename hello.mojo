#!/usr/bin/env mojo

import net
from net.socket import socket
import libc
from utils import StaticTuple

fn main():
	print("Hello world")

	try:
		var sock = socket(net.AF_INET, net.SOCK_STREAM, 0)
		var ip_addr = StaticTuple[UInt8, 4](0,0,0,0)
		var addr = net.SockAddr(ip_addr, 8080)
		sock.bind(addr)
	except e:
		print(e)
		libc.exit(-1)
	
