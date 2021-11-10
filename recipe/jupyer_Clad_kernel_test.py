import unittest
import jupyter_kernel_test


class CladXCppTests(jupyter_kernel_test.KernelTests):

    kernel_name = 'xcpp14-Clad'

    # language_info.name in a kernel_info_reply should match this
    language_name = 'c++'

    # Code in the kernel's language to write "hello, world" to stdout
    code_hello_world = '#include <iostream>\nstd::cout << "hello, world" << std::endl;'''

    # Code in the kernel's language to import Clad
    code_import_Clad = '#include "clad/Differentiator/Differentiator.h";'''

    # Samples of code which generate a Clad gradient
    code_Clad_gradient_result = [
        {
            'code': '#include "clad/Differentiator/Differentiator.h"\ndouble f(double x) {return x*x;};\nauto f_g = clad::gradient(f);\nf_g.dump();''',
            'result': 'The code is: void f_grad(double x, clad::array_ref<double> _d_x) {\ndouble _t2;\ndouble _t3;\n_t3 = x;\n_t2 = x;\ndouble f_return = _t3 * _t2;\ngoto _label0;\n_label0:\n{\ndouble _r0 = 1 * _t2;\n* _d_x += _r0;\ndouble _r1 = _t3 * 1;\n* _d_x += _r1;\n}\n}'
        }
    ]


if __name__ == '__main__':
    unittest.main()