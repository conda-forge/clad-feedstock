import unittest
import platform
import nbformat
import papermill as pm
import os
import sys

if platform.system() != 'Windows':
    class XCppNotebookTests(unittest.TestCase):

        notebook_paths = []

        def test_notebooks(self):
            for path in self.notebook_paths:
                inp = path
                out = f'{os.path.splitext(path)[0]}_output.ipynb'

                with open(inp) as f:
                    input_nb = nbformat.read(f, as_version=4)

                try:
                    # Execute the notebook
                    executed_notebook = pm.execute_notebook( 
                        inp, 
                        out,
                        log_output=True,
                        kernel_name='xcpp17-Clad'
                    )

                    if executed_notebook is None:
                        self.fail(f"Execution of notebook {path} returned None")
                except Exception as e:
                    self.fail(f"Notebook {path} failed to execute: {e}")

                with open(out) as f:
                    output_nb = nbformat.read(f, as_version=4)

                for i, (input_cell, output_cell) in enumerate(zip(input_nb.cells, output_nb.cells)):
                    if input_cell.cell_type == 'code' and output_cell.cell_type == 'code':
                        if bool(input_cell.outputs) != bool(output_cell.outputs):
                            self.fail(f"Cell {i} in notebook {path} has mismatched output presence")
                        else:
                            if input_cell.outputs != output_cell.outputs:
                                self.fail(f"Cell {i} in notebook {path} has mismatched output type")

                try:
                    os.remove(out)
                except Exception as e:
                    self.fail(f"Failed to delete output file {out}: {e}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python script.py <notebook1.ipynb> [<notebook2.ipynb> ...]")
        sys.exit(1)

    XCppNotebookTests.notebook_paths = sys.argv[1:]
    unittest.main(argv=[sys.argv[0]])
