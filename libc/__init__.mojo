
fn exit(code: UInt8):
	external_call["exit", NoneType](code)

fn errno() -> Int32:
	return external_call["__errno_location", Pointer[Int32]]()[]


	
