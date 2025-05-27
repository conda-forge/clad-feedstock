import unittest
import jupyter_kernel_test


class CladXCppTests(jupyter_kernel_test.KernelTests):

    kernel_name = 'xcpp20-Clad'

    # xeus-cpp uses "C++" in language_info.name
    language_name = 'C++'

    # Code in the kernel's language to write "hello, world" to stdout
    code_hello_world = '#include <iostream>\nstd::cout << "hello, world" << std::endl;'

    def test_clad_forward_mode_output(self):
        code = '''#include "clad/Differentiator/Differentiator.h"
#include <iostream>
double f(double x) { return x * x; }
auto f_g = clad::differentiate(f);
std::cout << f_g.execute(2) << std::endl;'''
        reply, output_msgs = self.execute_helper(code)

        # Look for stream messages
        stream_msgs = [msg for msg in output_msgs if msg['msg_type'] == 'stream']
        # Extract stdout text from all stream messages
        stdout_texts = [msg['content']['text'] for msg in stream_msgs if msg['content']['name'] == 'stdout']

        combined_stdout = ''.join(stdout_texts).strip()

        # Assert that the expected value is in the output
        self.assertIn('4', combined_stdout)

if __name__ == '__main__':
    unittest.main()
