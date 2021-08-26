#!/usr/bin/env python3
""" HIASHDI Helper Module

This module provides helper functions that allow the HIASBCH component
to communicate with the HIASHDI Historical Data Interface.

MIT License

Copyright (c) 2021 Asociación de Investigacion en Inteligencia Artificial
Para la Leucemia Peter Moss

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files(the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Contributors:
- Adam Milton-Barker

"""

import json
import requests


class hiashdi():
    """ HIASHDI Helper Module

    This module provides helper functions that allow the HIASBCH
    component to communicate with the HIASHDI Historical Data Interface.
    """

    def __init__(self, helpers):
        """ Initializes the class. """

        self.helpers = helpers
        self.program = "HIASHDI Helper Module"

        self.headers = {
            "accept": self.helpers.confs["agent"]["api"]["content"],
            "content-type": self.helpers.confs["agent"]["api"]["content"]
        }

        self.auth = (self.helpers.credentials["hiashdi"]["un"],
                    self.helpers.confs["agent"]["proxy"]["up"])

        self.helpers.logger.info("HIASHDI initialization complete.")

    def insert_data(self, typeof, data):
        """ Inserts data into HIASHDI. """

        apiHost = "https://" + self.helpers.credentials["server"]["host"] + "/" \
                    + self.helpers.credentials["hiashdi"]["endpoint"]
        apiEndpoint = "/data?type=" + typeof
        apiURL = apiHost + apiEndpoint

        response = requests.post(apiURL, data=json.dumps(
            data), headers=self.headers, auth=self.auth)

        if response.status_code == 201:
            return response.headers["Id"]
        else:
            return False
