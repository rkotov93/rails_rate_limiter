require 'rspec/rails'

RSpec.describe FakeController, type: :controller do
  before do
    request.env['HTTP_ACCEPT'] = 'application/json'
  end

  describe '.rate_limit' do
    context 'without block' do
      it 'raises an error' do
        expect { described_class.class_eval { rate_limit } }
          .to raise_error(RailsRateLimiter::Error)
      end
    end

    context 'with block' do
      let(:result) { instance_double RailsRateLimiter::Result }
      let(:strategy) do
        instance_double RailsRateLimiter::Strategies::SlidingWindowLog
      end

      before do
        allow(FakeController).to receive(:before_action)
        allow(RailsRateLimiter::Strategies::SlidingWindowLog)
          .to receive(:new).with(123, 56.minutes, 'custom_current-user-id', nil).and_return(strategy)
        allow(strategy).to receive(:run).and_return(result)
        allow(result).to receive(:limit_exceeded?).and_return(limit_exceeded)
        allow(result).to receive(:time_left)

        FakeController.class_eval do
          rate_limit limit: 123, per: 56.minutes, pattern: -> { current_user_id } do |info|
            render json: info.time_left
          end
        end
        get :test
      end

      context 'when limit exceeded' do
        let(:limit_exceeded) { true }

        it 'runs required operations' do
          expect(FakeController).to have_received(:before_action)
          expect(strategy).to have_received(:run)
          expect(result).to have_received(:time_left)
        end
      end

      context 'when limit is not exceeded' do
        let(:limit_exceeded) { false }

        it 'runs required operations' do
          expect(FakeController).to have_received(:before_action)
          expect(strategy).to have_received(:run)
        end
      end
    end
  end
end
