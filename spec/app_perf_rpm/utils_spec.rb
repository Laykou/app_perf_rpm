require 'spec_helper'

describe AppPerfRpm::Utils do
  it "should log source and backtrace" do
    AppPerfRpm.config.instrumentation[:test] = {
      :backtrace => :all,
      :source => true
    }
    span = AppPerfRpm::Tracing::Span.new(nil, "operation", nil)
    expect(span).to receive(:log).with(
      event: "backtrace",
      stack: anything
    ).and_call_original
    expect(span).to receive(:log).with(
      event: "source",
      stack: anything
    ).and_call_original
    AppPerfRpm::Utils.log_source_and_backtrace(span, :test)

    expect(span.log_entries[0]["fields"][:stack].length).to eql(26)
    expect(span.log_entries[1]["fields"][:stack][0..1]).to eql([
      {
        "file"=>"[APP_PATH]/lib/app_perf_rpm/backtrace.rb",
        "code"=>{
          43=>"      #end\n",
          44=>"\n",
          45=>"      def source_extract(backtrace: Kernel.caller(0))\n",
          46=>"        Array(backtrace).select {|bt| bt[/^\#{::AppPerfRpm.config.app_root.to_s}\\//] }.map do |trace|\n",
          47=>"          file, line_number = extract_file_and_line_number(trace)\n",
          48=>"          source_to_hash(file, line_number)\n"
        },
        "line_number"=>45
      },
      {
        "file"=>"[APP_PATH]/lib/app_perf_rpm/utils.rb",
        "code"=>{
          34=>"      end\n",
          35=>"      if config[:source]\n",
          36=>"        source = AppPerfRpm::Backtrace.source_extract\n",
          37=>"        if source.length > 0\n",
          38=>"          span.log(event: \"source\", stack: source)\n",
          39=>"        end\n"
        },
        "line_number"=>36
      }
    ])
  end

  it "should not log source and backtrace" do
    AppPerfRpm.config.instrumentation[:test] = {
      :backtrace => false,
      :source => false
    }
    span = AppPerfRpm::Tracing::Span.new(nil, "operation", nil)
    expect(span).to receive(:log).with(
      event: "backtrace",
      stack: anything
    ).never
    expect(span).to receive(:log).with(
      event: "source",
      stack: anything
    ).never
    AppPerfRpm::Utils.log_source_and_backtrace(span, :test)

    expect(span.log_entries[0]).to eql(nil)
    expect(span.log_entries[1]).to eql(nil)
  end
end