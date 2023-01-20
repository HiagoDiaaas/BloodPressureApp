import CoreBluetooth
import UIKit

let bloodPressureServiceCBUUID = CBUUID(string: "0x1810")
let systolicCharacteristicCBUUID = CBUUID(string: "2A58")
let diastolicCharacteristicCBUUID = CBUUID(string: "2A5A")
let meanArterialPressureCharacteristicCBUUID = CBUUID(string: "2A5E")

class BPMViewController: UIViewController {

    @IBOutlet weak var systolicLabel: UILabel!
    @IBOutlet weak var diastolicLabel: UILabel!
    @IBOutlet weak var meanArterialPressureLabel: UILabel!
  
    var centralManager: CBCentralManager!
    var bloodPressurePeripheral: CBPeripheral!
    var systolic: Int?
    var diastolic: Int?
    var meanArterialPressure: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func onBloodPressureReceived(_ systolic: Int, _ diastolic: Int, _ meanArterialPressure: Int) {
        systolicLabel.text = String(systolic)
        diastolicLabel.text = String(diastolic)
        meanArterialPressureLabel.text = String(meanArterialPressure)
        print("Systolic: \(systolic), Diastolic: \(diastolic), Mean Arterial Pressure: \(meanArterialPressure)")
    }
}

extension BPMViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
          case .unknown:
            print("central.state is .unknown")
          case .resetting:
            print("central.state is .resetting")
          case .unsupported:
            print("central.state is .unsupported")
          case .unauthorized:
            print("central.state is .unauthorized")
          case .poweredOff:
            print("central.state is .poweredOff")
          case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: [bloodPressureServiceCBUUID])
        @unknown default:
            print("ERROR")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        bloodPressurePeripheral = peripheral
        bloodPressurePeripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(bloodPressurePeripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        bloodPressurePeripheral.discoverServices([bloodPressureServiceCBUUID])
    }
}

extension BPMViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case systolicCharacteristicCBUUID:
            systolic = bloodPressure(from: characteristic)
            checkAllValuesReceived()
        case diastolicCharacteristicCBUUID:
            diastolic = bloodPressure(from: characteristic)
            checkAllValuesReceived()
        case meanArterialPressureCharacteristicCBUUID:
            meanArterialPressure = bloodPressure(from: characteristic)
            checkAllValuesReceived()
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    private func bloodPressure(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)

        // Extract the blood pressure value from the characteristic data using bitwise operations
        // This is just an example, you should refer to the documentation of your specific device and service to understand how the data is encoded
        let bloodPressureValue = (Int(byteArray[0]) & 0xFF) | (Int(byteArray[1]) << 8)
        return bloodPressureValue
    }
    
    private func checkAllValuesReceived(){
        if let systolic = systolic, let diastolic = diastolic, let meanArterialPressure = meanArterialPressure{
            onBloodPressureReceived(systolic, diastolic, meanArterialPressure)
        }
    }
}
