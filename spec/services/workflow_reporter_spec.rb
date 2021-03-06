# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowReporter do
  let(:druid) { 'jj925bx9565' }
  let(:namespaced_druid) { "druid:#{druid}" }
  let(:version) { '1' }
  let(:err_msg) { "Failed to retrieve response #{Settings.workflow_services_url}/preservationAuditWF/something (HTTP status 404)" }
  let(:wf_server_response_json) { { some: 'json response from wf server' } }

  before do
    allow(Dor::Workflow::Client).to receive(:new).and_return(stub_wf_client)
  end

  describe '.create_wf' do
    let(:stub_wf_client) { instance_double(Dor::Workflow::Client) }

    before do
      allow(stub_wf_client).to receive(:create_workflow_by_name)
    end

    context 'when passed a namespaced druid' do
      it 'passes the supplied druid along to the workflow client' do
        described_class.send(:create_wf, namespaced_druid, version)

        expect(stub_wf_client).to have_received(:create_workflow_by_name)
          .once
          .with(namespaced_druid, described_class::PRESERVATIONAUDITWF, version: version)
      end
    end

    context 'when passed a bare druid' do
      it 'adds a namespace to the druid and sends it to the workflow client' do
        described_class.send(:create_wf, druid, version)

        expect(stub_wf_client).to have_received(:create_workflow_by_name)
          .once
          .with(namespaced_druid, described_class::PRESERVATIONAUDITWF, version: version)
      end
    end
  end

  describe '.report_error' do
    let(:process_name) { 'moab-valid' }
    let(:audit_result) { 'Invalid moab, validation error...ential version directories.' }

    context 'when workflow already exists' do
      let(:stub_wf_client) { instance_double(Dor::Workflow::Client, update_error_status: wf_server_response_json) }

      it 'returns json response from wf server (mocked here)' do
        expect(described_class.report_error(druid, version, process_name, audit_result)).to eq wf_server_response_json
        expect(stub_wf_client).to have_received(:update_error_status)
          .with(druid: "druid:#{druid}",
                workflow: 'preservationAuditWF',
                process: process_name,
                error_msg: audit_result)
      end
    end

    context 'when workflow does not exist' do
      let(:stub_wf_client) { instance_double(Dor::Workflow::Client) }

      before do
        allow(described_class).to receive(:create_wf)
        allow(described_class).to receive(:report_error).and_call_original
        # AFAICT, this is how one gets RSpec to vary behavior on subsequent
        # calls that raise and return
        call_count = 0
        allow(stub_wf_client).to receive(:update_error_status) do
          call_count += 1
          call_count == 1 ? raise(Dor::MissingWorkflowException, err_msg) : nil
        end
      end

      it 'creates workflow and calls report_error again' do
        described_class.report_error(druid, version, process_name, audit_result)

        expect(described_class).to have_received(:create_wf).once
        expect(described_class).to have_received(:report_error).twice
      end
    end
  end

  describe '.report_completed' do
    let(:process_name) { 'preservation-audit' }

    context 'when workflow exists' do
      let(:stub_wf_client) { instance_double(Dor::Workflow::Client, update_status: wf_server_response_json) }

      it 'returns json response from wf server (mocked here)' do
        expect(described_class.report_completed(druid, version, process_name)).to eq wf_server_response_json
        expect(stub_wf_client).to have_received(:update_status)
          .with(druid: "druid:#{druid}",
                workflow: 'preservationAuditWF',
                process: process_name,
                status: 'completed')
      end
    end

    context 'when workflow does not exist' do
      let(:stub_wf_client) { instance_double(Dor::Workflow::Client) }

      before do
        allow(described_class).to receive(:create_wf)
        allow(described_class).to receive(:report_completed).and_call_original
        # AFAICT, this is how one gets RSpec to vary behavior on subsequent
        # calls that raise and return
        call_count = 0
        allow(stub_wf_client).to receive(:update_status) do
          call_count += 1
          call_count == 1 ? raise(Dor::MissingWorkflowException, err_msg) : nil
        end
      end

      it 'creates workflow and calls report_completed again' do
        described_class.report_completed(druid, version, process_name)

        expect(described_class).to have_received(:create_wf).once
        expect(described_class).to have_received(:report_completed).twice
      end
    end
  end
end
