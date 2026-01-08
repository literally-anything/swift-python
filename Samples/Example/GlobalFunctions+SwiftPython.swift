import SwiftPython
import CPython
@_documentation(visibility: private) func _example_hello(self _: Optional<UnsafeMutablePointer<CPython.PyObject>>, args: Optional<UnsafeMutablePointer<CPython.PyObject>>) -> Optional<UnsafeMutablePointer<CPython.PyObject>> {
    let argument: SwiftPython.PythonObject = SwiftPython.PythonObject(unsafeUnmanaged: args!)
    do throws(SwiftPython.PythonError) {
        let returnValue = hello(text: try String(argument))
        return try returnValue.convertToPythonObject().take()
    } catch let error {
        error.raise()
        return nil
    }
}