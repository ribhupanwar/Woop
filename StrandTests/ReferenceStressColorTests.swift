import XCTest
import StrandDesign
@testable import Strand

final class ReferenceStressColorTests: XCTestCase {
    func testStressWordsUseTheirBandColorsRatherThanRecoveryGreen() {
        XCTAssertEqual(StressBand(score: 0.5).color, WoopHomePalette.stressLow)
        XCTAssertEqual(StressBand(score: 1.2).color, WoopHomePalette.healthGood)
        XCTAssertEqual(StressBand(score: 2.5).color, WoopHomePalette.stressHigh)
        XCTAssertEqual(StressRamp.labelColor(0.5), StressBand.low.color)
    }
    func testReferenceRecoveryIsDiscreteAndUsesNeonGreenAboveSixtySix() {
        XCTAssertEqual(WoopHomePalette.recovery(81), WoopHomePalette.recoveryGood)
        XCTAssertEqual(WoopHomePalette.recovery(50), WoopHomePalette.recoveryWarning)
        XCTAssertEqual(WoopHomePalette.recovery(27), WoopHomePalette.recoveryLow)
    }
}
