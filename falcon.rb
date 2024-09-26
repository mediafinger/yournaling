#!/usr/bin/env -S falcon host
# frozen_string_literal: true

load :rack

hostname = File.basename(__dir__)
port = AppConf.yournaling_port

rack hostname do
  append preload "preload.rb"
  endpoint Async::HTTP::Endpoint.parse("http://0.0.0.0:#{port}")
end
