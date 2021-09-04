/*
 * Copyright (C) 2021 Aclima, Inc.
 * This file is part of iot2web - https://github.com/Aclima/iot2web
 */

/* eslint @typescript-eslint/no-unused-expressions: "off" */

import * as iot from "@google-cloud/iot";
import chai from "chai";

describe("Google Cloud IoT Core", function () {
  it("should be imported", async function () {
    chai.expect(iot).to.be.an("object");
  });
});
