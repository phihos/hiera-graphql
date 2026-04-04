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
    context 'when key matches confine_to_key' do
      hiera_key = 'foo'
      lookup_key = 'somelookup'
      let(:options) do
        {
          'confine_to_key' => hiera_key,
          'graphql_query_opts_lookup_key' => lookup_key
        }
      end

      it 'returns the GraphQL query result' do
        query_opts = {}
        query_result = { 'device_list' => [] }
        expect(function).to receive(:call_function).with('lookup', lookup_key).and_return(query_opts)
        expect(function).to receive(:call_function).with('graphql::graphql_query', query_opts).and_return(query_result)
        expect(function.lookup_key(hiera_key, options, context)).to eq(query_result)
      end

      it 'calls context.not_found when query returns nil' do
        query_opts = {}
        expect(function).to receive(:call_function).with('lookup', lookup_key).and_return(query_opts)
        expect(function).to receive(:call_function).with('graphql::graphql_query', query_opts).and_return(nil)
        function.lookup_key(hiera_key, options, context)
        expect(context).to have_received(:not_found)
      end
    end

    context 'when key does not match confine_to_key' do
      let(:options) do
        {
          'confine_to_key' => 'expected_key',
          'graphql_query_opts_lookup_key' => 'somelookup'
        }
      end

      it 'calls context.not_found' do
        function.lookup_key('other_key', options, context)
        expect(context).to have_received(:not_found)
      end

      it 'logs a skip message via context.explain' do
        function.lookup_key('other_key', options, context)
        expect(context).to have_received(:explain)
      end
    end

    context 'when confine_to_key option is missing' do
      let(:options) do
        {
          'graphql_query_opts_lookup_key' => 'somelookup'
        }
      end

      it 'raises an ArgumentError' do
        expect {
          function.lookup_key('foo', options, context)
        }.to raise_error(ArgumentError, %r{confine_to_key must be a string})
      end
    end

    context 'when confine_to_key option is not a string' do
      let(:options) do
        {
          'confine_to_key' => 42,
          'graphql_query_opts_lookup_key' => 'somelookup'
        }
      end

      it 'raises an ArgumentError' do
        expect {
          function.lookup_key('foo', options, context)
        }.to raise_error(ArgumentError, %r{confine_to_key must be a string})
      end
    end

    context 'when graphql_query_opts_lookup_key option is missing' do
      let(:options) do
        {
          'confine_to_key' => 'foo'
        }
      end

      it 'raises an ArgumentError' do
        expect {
          function.lookup_key('foo', options, context)
        }.to raise_error(ArgumentError, %r{graphql_query_opts_lookup_key must be a string})
      end
    end

    context 'when graphql_query_opts_lookup_key option is not a string' do
      let(:options) do
        {
          'confine_to_key' => 'foo',
          'graphql_query_opts_lookup_key' => ['not', 'a', 'string']
        }
      end

      it 'raises an ArgumentError' do
        expect {
          function.lookup_key('foo', options, context)
        }.to raise_error(ArgumentError, %r{graphql_query_opts_lookup_key must be a string})
      end
    end
  end
end
