RSpec.shared_examples 'a rate limits sliding window log strategy' do
  describe '#run' do
    let(:result) { double('result') }
    let!(:freezed_time) { Time.zone.now }
    let(:limit) { 1 }

    before do
      allow(RailsRateLimiter::Result).to receive(:new).and_return(result)
      score = ((freezed_time + expires_in).to_f * accuracy).to_i
      value = (freezed_time.to_f * accuracy).to_i
      redis_mock.zadd(cache_key, score, value)
    end

    context 'when limit exceeded' do
      let(:expires_in) { 10.seconds }

      before { freeze_time }

      it 'returns result with time left in seconds' do
        expect(RailsRateLimiter::Result).to receive(:new).with(10)
        expect(strategy.run).to be == result
      end
    end

    context 'when limit is not exceeded' do
      let(:limit) { 2 }
      let(:expires_in) { 2.hours }
      let(:added) { (freezed_time.to_f * accuracy).to_i }
      let(:expiring) { ((freezed_time + 1.hour).to_f * accuracy).to_i }

      before { freeze_time }

      it 'returns result with 0 seconds left' do
        expect(RailsRateLimiter::Result).to receive(:new).with(0)
        expect(strategy.run).to be == result
        pair = redis_mock.zrange(cache_key, 0, 0, with_scores: true)[0]
        expect(pair).to be == [added.to_s, expiring.to_f]
      end
    end

    context 'with expired set members' do
      let(:expires_in) { 2.hour }

      before do
        score = ((freezed_time - 1.minute).to_f * accuracy).to_i
        value = ((freezed_time - 61.minutes).to_f * accuracy).to_i
        redis_mock.zadd(cache_key, score, value)
        strategy.run
      end

      it 'removes expired member' do
        expect(redis_mock.zcard(cache_key)).to be == 1
      end
    end
  end
end

RSpec.describe RailsRateLimiter::Strategies::SlidingWindowLog do
  subject(:strategy) { described_class.new(limit, 1.hour, requester) }

  let(:accuracy) { described_class::TIMESTAMP_ACCURACY }
  let!(:redis_mock) { mock_redis }
  let(:freeze_time) do
    zone = double('zone')
    allow(Time).to receive(:zone).and_return(zone)
    allow(zone).to receive(:now).and_return(freezed_time)
  end

  context 'when requester is ip address' do
    let(:requester) { '127.0.0.1' }
    let(:cache_key) { "rate_limiter_ip_#{requester}" }

    it_behaves_like 'a rate limits sliding window log strategy'
  end

  context 'when requester is a custom entity' do
    let(:custom_entity) { Object.new }
    let(:requester) { Proc.new { custom_entity.object_id } }
    let(:cache_key) { "rate_limiter_custom_#{custom_entity.object_id}" }

    it_behaves_like 'a rate limits sliding window log strategy'
  end
end
