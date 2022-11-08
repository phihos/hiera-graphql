require 'spec_helper'

require 'puppet/functions/hiera_graphql'

describe FakeFunction do # rubocop:disable FilePath
  let(:function) { described_class.new }
  let(:context) { instance_double('Puppet::LookupContext') }

  before(:each) do
    allow(context).to receive(:cache_has_key)
    allow(context).to receive(:explain)
    allow(context).to receive(:interpolate) do |val|
      val
    end
    allow(context).to receive(:cache)
    allow(context).to receive(:not_found)
    allow(context).to receive(:interpolate).with('/path').and_return('/path')
  end

  describe '#lookup_key' do
    context 'Should run' do
      hiera_key = 'foo'
      lookup_key = 'somelookup'
      let(:options) do
        {
          'confine_to_key' => hiera_key,
          'graphql_query_opts_lookup_key' => lookup_key
        }
      end

      it 'runs' do
        query_opts = {}
        query_result = {}
        expect(function).to receive(:call_function).with('lookup', lookup_key).and_return(query_opts)
        expect(function).to receive(:call_function).with('graphql::graphql_query', query_opts).and_return(query_result)
        expect(function.lookup_key(hiera_key, options, context)).to eq(query_result)
      end
    end
  end
end
