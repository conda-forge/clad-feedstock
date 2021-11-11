import unittest
import jupyter_kernel_test


class CladXCppTests(jupyter_kernel_test.KernelTests):

    kernel_name = 'xcpp14-Clad'

    # language_info.name in a kernel_info_reply should match this
    language_name = 'c++'

    # Code in the kernel's language to write "hello, world" to stdout
    code_hello_world = '#include <iostream>\nstd::cout << "hello, world" << std::endl;'''

   # Code for Clad forward mode testing 
    code_execute_result = [
        {
            'code': '#include "clad/Differentiator/Differentiator.h"\ndouble f(double x) {return x*x;};\nauto f_g = clad::differentiate(f);\nf_g.execute(2)',
            'result': '4.0000000'
        }
    ]

if __name__ == '__main__':
    unittest.main()