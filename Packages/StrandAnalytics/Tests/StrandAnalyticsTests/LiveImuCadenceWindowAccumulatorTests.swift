import XCTest
import WhoopProtocol
@testable import StrandAnalytics

final class LiveImuCadenceWindowAccumulatorTests: XCTestCase {
    private func frame(_ second: Int, cadenceHz: Double = 1.8) -> Whoop5ImuFrame {
        let samples = (0..<100).map { index -> RawImuSample in
            let phase = 2.0 * Double.pi * cadenceHz * Double(index) / 100.0
            return RawImuSample(ax: 1.0 + 0.12 * sin(phase), ay: 0, az: 0,
                                gx: 0, gy: 0, gz: 0)
        }
        return Whoop5ImuFrame(baseTs: 1_000_020 + second, sampleRateHz: 100, samples: samples)
    }

    func testEmitsMinuteSummaryOnlyWhenNextMinuteArrives() {
        var accumulator = LiveImuCadenceWindowAccumulator()
        for second in 0..<60 {
            XCTAssertNil(accumulator.ingest(frame(second), averageBpm: 68))
        }
        let completed = accumulator.ingest(frame(60), averageBpm: 70)
        XCTAssertNotNil(completed)
        XCTAssertEqual(completed?.startTs, (1_000_020 / 60) * 60)
        XCTAssertEqual(completed?.sampleCount, 6_000)
        XCTAssertEqual(completed?.averageBpm, 68)
        XCTAssertEqual(completed?.cadenceHz ?? 0, 1.8, accuracy: 0.15)
        XCTAssertGreaterThanOrEqual(completed?.rhythmStrength ?? 0, ImuFeatureExtractor.minCadenceStrength)
    }

    func testDuplicateAndOutOfOrderFramesDoNotInflateSampleCount() {
        var accumulator = LiveImuCadenceWindowAccumulator()
        for second in 0..<30 { _ = accumulator.ingest(frame(second)) }
        _ = accumulator.ingest(frame(29))
        _ = accumulator.ingest(frame(12))
        for second in 30..<60 { _ = accumulator.ingest(frame(second)) }
        let completed = accumulator.ingest(frame(60))
        XCTAssertEqual(completed?.sampleCount, 6_000)
    }

    func testPartialMinuteIsReportedButCannotMeetMinimumSampleGate() {
        var accumulator = LiveImuCadenceWindowAccumulator()
        for second in 0..<20 { _ = accumulator.ingest(frame(second)) }
        let partial = accumulator.finish()
        XCTAssertEqual(partial?.sampleCount, 2_000)
        XCTAssertTrue(MotionCadenceBoutDetector.detect([partial!]).isEmpty)
    }

    func testInvalidFrameShapeIsIgnored() {
        var accumulator = LiveImuCadenceWindowAccumulator()
        let invalid = Whoop5ImuFrame(baseTs: 1_000_020, sampleRateHz: 50,
                                     samples: Array(frame(0).samples.prefix(50)))
        XCTAssertNil(accumulator.ingest(invalid))
        XCTAssertNil(accumulator.finish())
    }
}
