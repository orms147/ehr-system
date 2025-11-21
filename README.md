# 📋 REVIEW TOÀN BỘ CHỨC NĂNG HỆ THỐNG EHR

## 🎯 TỔNG QUAN

Hệ thống EHR bao gồm **5 contracts chính** với **4 interfaces**, quản lý:
- ✅ **Access Control**: Vai trò người dùng (Patient, Doctor, Organization)
- ✅ **Record Management**: Metadata hồ sơ y tế trên IPFS
- ✅ **Consent Management**: Quản lý quyền truy cập với EIP-712
- ✅ **Doctor-Initiated Flow**: Bác sĩ tạo hồ sơ + Ownership Claim
- ✅ **Delegate Request**: Workflow request/approve delegate access
- ✅ **Emergency Controls**: Pause/Unpause system

---

## 📦 1. EHRSystemSecure.sol
### *Contract chính - Orchestrator*

### **🔧 Constructor**
```solidity
constructor()
```
- ✅ Khởi tạo AccessControl, RecordRegistry, ConsentLedgerSecure
- ✅ Set consentLedger cho RecordRegistry
- ✅ Authorize EHRSystemSecure để gọi grantInternal
- ✅ Emit SystemInitialized event

### **👤 Role Management (Wrapper)**
```solidity
function registerRole(IAccessControl.Role role) external
```
- **Access**: Public (với `whenNotPaused`)
- **Chức năng**: Đăng ký vai trò cho msg.sender
- **Use Case**: User tự đăng ký role đầu tiên

### **📝 Record Management (Wrapper)**
```solidity
function addRecord(string memory cid, string memory parentCID, string memory recordType) external
```
- **Access**: Public (với `whenNotPaused`)
- **Chức năng**: Patient tạo record mới
- **Use Case**: Patient tự tạo hồ sơ y tế

```solidity
function claimOwnership(string memory cid) external
```
- **Access**: Public (với `whenNotPaused`)
- **Chức năng**: Patient claim ownership từ Doctor
- **Use Case**: Doctor-Initiated Flow - Patient nhận quyền sở hữu

### **🔐 Consent Management (Wrapper)**
```solidity
function grantConsent(address grantee, string memory rootCID, bytes32 encKeyHash, uint256 expireAt, bool includeUpdates, bool allowDelegate) external
```
- **Access**: Public (với `whenNotPaused`)
- **Chức năng**: Grant consent cho grantee
- **Use Case**: Patient cấp quyền truy cập cho Doctor/Organization

```solidity
function revokeConsent(string memory rootCID, address grantee) external
```
- **Access**: Public (với `whenNotPaused`)
- **Chức năng**: Revoke consent đã cấp
- **Use Case**: Patient thu hồi quyền truy cập

### **🔄 Delegate Request Flow**
```solidity
function requestDelegateAccess(address patient, string memory rootCID) external
```
- **Access**: Doctor only (với `whenNotPaused`)
- **Chức năng**: Doctor request delegate access từ patient
- **Use Case**: Doctor cần truy cập record của patient
- **Events**: DelegateRequested

```solidity
function approveDelegate(bytes32 reqId, bytes32 encKeyHash) external
```
- **Access**: Organization only (với `whenNotPaused`)
- **Chức năng**: Organization approve và grant consent (30 ngày)
- **Use Case**: Grant Internal - Organization quyết định cấp quyền
- **Events**: DelegateApproved

```solidity
function getDelegateRequest(bytes32 reqId) external view returns (DelegateRequest memory)
```
- **Access**: Public view
- **Chức năng**: Lấy thông tin delegate request

### **🛡️ Emergency Controls**
```solidity
function pause() external
```
- **Access**: Owner only
- **Chức năng**: Tạm dừng toàn bộ hệ thống
- **Events**: EmergencyPause

```solidity
function unpause() external
```
- **Access**: Owner only
- **Chức năng**: Khôi phục hệ thống
- **Events**: EmergencyUnpause

### **⚙️ Admin Functions**
```solidity
function authorizeContractForGrant(address contractAddress) external
```
- **Access**: Owner only
- **Chức năng**: Authorize contract để gọi grantInternal
- **Use Case**: Cho phép DoctorUpdate contract sử dụng auto-grant

### **📊 Events**
- `SystemInitialized` - Hệ thống khởi tạo
- `EmergencyPause` - Hệ thống tạm dừng
- `EmergencyUnpause` - Hệ thống khôi phục
- `DelegateRequested` - Doctor request access
- `DelegateApproved` - Organization approve request

---

## 📦 2. AccessControl.sol
### *Quản lý vai trò người dùng*

### **👤 Role Registration**
```solidity
function registerRole(address user, Role role) external
```
- **Access**: Public
- **Chức năng**: Đăng ký vai trò cho user
- **Validation**: 
  - User chưa đăng ký
  - Role != None
- **Events**: RoleRegistered

```solidity
function updateRole(address user, Role newRole) external
```
- **Access**: Public (chỉ user tự update)
- **Chức năng**: Cập nhật vai trò
- **Validation**: 
  - User đã đăng ký
  - newRole != None
  - msg.sender == user
- **Events**: RoleUpdated

### **🔍 Role Queries**
```solidity
function getRole(address user) external view returns (Role)
function isPatient(address user) external view returns (bool)
function isDoctor(address user) external view returns (bool)
function isOrganization(address user) external view returns (bool)
function roles(address user) external view returns (Role)
function isRegistered(address user) external view returns (bool)
```
- **Access**: Public view
- **Chức năng**: Kiểm tra vai trò và trạng thái đăng ký

### **📊 Events**
- `RoleRegistered` - User đăng ký role
- `RoleUpdated` - User cập nhật role

### **🎭 Roles**
- `None` - Chưa có vai trò
- `Patient` - Bệnh nhân
- `Doctor` - Bác sĩ
- `Organization` - Tổ chức y tế

---

## 📦 3. RecordRegistry.sol
### *Quản lý metadata hồ sơ y tế*

### **⚙️ Setup**
```solidity
function setConsentLedger(IConsentLedger _consentLedger) external
```
- **Access**: Public (chỉ gọi 1 lần)
- **Chức năng**: Set consentLedger để kiểm tra consent trong claimOwnership
- **Validation**: Chưa được set, authorized caller

### **📝 Record Creation**
```solidity
function addRecord(string memory cid, string memory parentCID, string memory recordType) external
```
- **Access**: Patient only (`onlyPatient`)
- **Chức năng**: Patient tạo record mới
- **Validation**: 
  - CID không rỗng
  - Record chưa tồn tại
  - Parent record tồn tại (nếu có)
- **Logic**: 
  - `createdBy = msg.sender` (patient)
  - `owner = msg.sender` (patient)
  - Version tự động tính từ parent
- **Events**: RecordAdded

```solidity
function addRecordByOwner(string memory cid, string memory parentCID, string memory recordType, address owner) external
```
- **Access**: Doctor/Organization only
- **Chức năng**: Doctor/Organization tạo record cho owner
- **Use Case**: Doctor-Initiated Flow
- **Logic**: 
  - `createdBy = msg.sender` (doctor)
  - `owner = owner` (có thể là doctor hoặc patient)
- **Events**: RecordAdded

```solidity
function _addRecord(string memory cid, string memory parentCID, string memory recordType, address owner) internal
```
- **Access**: Internal
- **Chức năng**: Internal function để tạo record
- **Logic**: Xử lý version, parent-child relationship

### **🔄 Record Update**
```solidity
function updateRecordCID(string memory oldCID, string memory newCID) external
```
- **Access**: Owner only
- **Chức năng**: Cập nhật CID (dùng cho re-encryption)
- **Validation**: 
  - Old record tồn tại
  - msg.sender là owner
  - New CID chưa tồn tại
- **Logic**: Giữ nguyên `createdBy`, cập nhật `createdAt`
- **Events**: RecordUpdated

### **👑 Ownership Transfer**
```solidity
function claimOwnership(string memory cid) external
```
- **Access**: Patient only
- **Chức năng**: Patient claim ownership từ Doctor
- **Validation**: 
  - Record tồn tại
  - msg.sender chưa là owner
  - msg.sender là Patient
  - Có active consent từ current owner
  - Consent chưa hết hạn
- **Use Case**: Doctor-Initiated Flow
- **Events**: OwnershipTransferred

```solidity
function transferOwnership(string memory cid, address newOwner) public
```
- **Access**: Owner hoặc contract này
- **Chức năng**: Transfer ownership
- **Validation**: 
  - Record tồn tại
  - newOwner != address(0)
  - msg.sender là owner hoặc contract này
- **Logic**: Cập nhật ownerRecords mapping
- **Events**: OwnershipTransferred

### **🔍 Record Queries**
```solidity
function getRecord(string memory cid) external view returns (Record memory)
function getOwnerRecords(address owner) external view returns (string[] memory)
function getChildRecords(string memory parentCID) external view returns (string[] memory)
function recordExists(string memory cid) external view returns (bool)
function records(string memory cid) external view returns (...)
```
- **Access**: Public view
- **Chức năng**: Truy vấn thông tin records

### **📊 Events**
- `RecordAdded` - Record được tạo
- `RecordUpdated` - Record được cập nhật CID
- `OwnershipTransferred` - Ownership được transfer

### **📋 Record Struct**
```solidity
struct Record {
    string cid;              // IPFS CID
    string parentCID;        // CID của record cha
    address createdBy;       // Người tạo (immutable)
    address owner;           // Chủ sở hữu hiện tại
    bytes32 recordTypeHash;  // Hash của recordType
    uint256 createdAt;       // Thời gian tạo
    uint8 version;           // Version (tự động tính)
    bool exists;            // Record tồn tại
}
```

---

## 📦 4. ConsentLedgerSecure.sol
### *Quản lý consent với EIP-712 và ReentrancyGuard*

### **🔐 Grant Consent**
```solidity
function grant(address grantee, string memory rootCID, bytes32 encKeyHash, uint256 expireAt, bool includeUpdates, bool allowDelegate) external
```
- **Access**: Public (với `nonReentrant`)
- **Chức năng**: Patient grant consent cho grantee
- **Validation**: 
  - grantee != address(0)
  - rootCID không rỗng
  - expireAt > block.timestamp hoặc == max
- **Logic**: 
  - Tăng nonce của patient
  - Lưu consent vào mapping
- **Events**: ConsentGranted

```solidity
function grantInternal(address patient, address grantee, string memory rootCID, bytes32 encKeyHash, uint256 expireAt, bool includeUpdates, bool allowDelegate) external
```
- **Access**: Authorized contracts only (với `nonReentrant`)
- **Chức năng**: Auto-grant consent (dùng cho DoctorUpdate, approveDelegate)
- **Validation**: 
  - msg.sender được authorize
  - Tương tự grant()
- **Use Case**: 
  - DoctorUpdate: Auto-grant cho patient và doctor
  - approveDelegate: Organization grant cho doctor
- **Events**: ConsentGranted

```solidity
function grantBySig(ConsentPermit memory permit, bytes memory signature) external
```
- **Access**: Public (với `nonReentrant`)
- **Chức năng**: Grant consent bằng EIP-712 signature
- **Validation**: 
  - Permit hợp lệ
  - Nonce đúng
  - Signature hợp lệ (patient ký)
- **Use Case**: Doctor-Initiated Flow - Doctor ký permit gửi patient
- **Events**: ConsentGranted

### **🔒 Revoke Consent**
```solidity
function revoke(string memory rootCID, address grantee) external
```
- **Access**: Public (với `nonReentrant`)
- **Chức năng**: Patient revoke consent
- **Validation**: 
  - Consent active
  - msg.sender là patient
- **Logic**: Set `active = false`
- **Events**: ConsentRevoked

### **🔄 Delegate Access**
```solidity
function delegate(string memory rootCID, address delegatee) external
```
- **Access**: Public (với `nonReentrant`)
- **Chức năng**: Grantee delegate access cho delegatee
- **Validation**: 
  - Consent active
  - allowDelegate = true
  - Consent chưa hết hạn
- **Logic**: 
  - Tạo consent mới cho delegatee
  - allowDelegate = false (không thể delegate tiếp)
- **Events**: DelegatedAccess

### **🔍 Consent Queries**
```solidity
function canAccess(address grantee, string memory cid) external view returns (bool)
function getConsent(address grantee, string memory rootCID) external view returns (Consent memory)
function getNonce(address patient) external view returns (uint256)
function consents(address grantee, string memory rootCID) external view returns (...)
function nonces(address patient) external view returns (uint256)
function DOMAIN_SEPARATOR() external view returns (bytes32)
```
- **Access**: Public view
- **Chức năng**: Truy vấn thông tin consent

### **⚙️ Authorization**
```solidity
function authorizeContract(address contractAddress) external
```
- **Access**: Public (cần được gọi từ EHRSystemSecure)
- **Chức năng**: Authorize contract để gọi grantInternal
- **Use Case**: Cho phép EHRSystemSecure, DoctorUpdate gọi grantInternal

### **📊 Events**
- `ConsentGranted` - Consent được cấp
- `ConsentRevoked` - Consent bị thu hồi
- `DelegatedAccess` - Access được delegate

### **📋 Consent Struct**
```solidity
struct Consent {
    address patient;         // Người grant
    address grantee;         // Người nhận
    string rootCID;         // CID của record
    bytes32 encKeyHash;     // Hash của encryption key
    uint256 issuedAt;       // Thời gian cấp
    uint256 expireAt;       // Thời gian hết hạn (max = vĩnh viễn)
    bool active;            // Consent còn active
    bool includeUpdates;    // Bao gồm updates
    bool allowDelegate;     // Cho phép delegate
    uint256 nonce;          // Nonce để chống replay
}
```

---

## 📦 5. DoctorUpdate.sol
### *Bác sĩ UPDATE + AUTO GRANT*

### **📝 Doctor-Initiated Record Creation**
```solidity
function addRecordByDoctor(string calldata cid, string calldata parentCID, address patient) external
```
- **Access**: Doctor only (`onlyDoctor`)
- **Chức năng**: Doctor tạo record cho patient và auto-grant consent
- **Validation**: 
  - patient != address(0)
  - patient là Patient role
- **Logic**:
  1. Tạo record với `owner = patient`
  2. Auto-grant cho patient (vĩnh viễn, `type(uint256).max`)
  3. Auto-grant cho doctor (7 ngày)
- **Events**: 
  - RecordAddedByDoctor
  - AutoGranted (2 lần)

### **📊 Events**
- `RecordAddedByDoctor` - Doctor tạo record
- `AutoGranted` - Consent được auto-grant

---

## 🔄 WORKFLOWS CHÍNH

### **1. Patient Self-Registration Flow**
```
1. User → registerRole(Patient)
2. User → addRecord(CID, "", "Initial")
   → createdBy = patient, owner = patient
```

### **2. Doctor-Initiated Flow**
```
1. Doctor → addRecordByOwner(CID, "", "Initial", patient)
   → createdBy = doctor, owner = patient
2. Doctor → grantBySig(permit, signature)
   → Grant consent cho patient
3. Patient → claimOwnership(CID)
   → owner = patient (nếu chưa là owner)
4. Patient → grant(patient, CID, max, ...)
   → Auto-grant vĩnh viễn cho bản thân
```

### **3. Doctor Update Flow (DoctorUpdate)**
```
1. Doctor → addRecordByDoctor(CID, parentCID, patient)
   → Tạo record + Auto-grant:
     - Patient: vĩnh viễn
     - Doctor: 7 ngày
```

### **4. Delegate Request Flow**
```
1. Doctor → requestDelegateAccess(patient, rootCID)
   → Tạo DelegateRequest
2. Organization → approveDelegate(reqId, encKeyHash)
   → Approve + Grant consent (30 ngày)
```

### **5. Consent Management Flow**
```
1. Patient → grantConsent(doctor, CID, ...)
   → Cấp quyền truy cập
2. Doctor → canAccess(doctor, CID)
   → Kiểm tra quyền truy cập
3. Patient → revokeConsent(CID, doctor)
   → Thu hồi quyền
```

### **6. Delegate Access Flow**
```
1. Patient → grantConsent(doctor, CID, ..., allowDelegate=true)
2. Doctor → delegate(CID, delegatee)
   → Delegate cho doctor khác
```

---

## 🛡️ SECURITY FEATURES

### **Access Control**
- ✅ Role-based access control (Patient, Doctor, Organization)
- ✅ Modifiers: `onlyPatient`, `onlyDoctor`, `onlyOrganization`
- ✅ Owner-only functions: `pause()`, `unpause()`, `authorizeContractForGrant()`

### **Reentrancy Protection**
- ✅ `nonReentrant` modifier trên tất cả state-changing functions trong ConsentLedgerSecure
- ✅ Checks-Effects-Interactions pattern

### **Input Validation**
- ✅ Address validation (không phải address(0))
- ✅ String validation (CID không rỗng)
- ✅ Existence checks (record tồn tại, consent active)
- ✅ Expiration checks (consent chưa hết hạn)

### **EIP-712 Signature**
- ✅ Domain separator
- ✅ Type hash cho ConsentPermit
- ✅ Signature recovery và validation

### **Emergency Controls**
- ✅ Pausable pattern (OpenZeppelin)
- ✅ Owner có thể pause/unpause toàn hệ thống

---

## 📊 EVENTS SUMMARY

| Contract | Events | Mục đích |
|----------|--------|----------|
| **EHRSystemSecure** | SystemInitialized, EmergencyPause, EmergencyUnpause, DelegateRequested, DelegateApproved | System events, delegate workflow |
| **AccessControl** | RoleRegistered, RoleUpdated | Role management |
| **RecordRegistry** | RecordAdded, RecordUpdated, OwnershipTransferred | Record lifecycle |
| **ConsentLedgerSecure** | ConsentGranted, ConsentRevoked, DelegatedAccess | Consent lifecycle |
| **DoctorUpdate** | RecordAddedByDoctor, AutoGranted | Doctor-initiated flow |

---

## ✅ TỔNG KẾT

### **Số lượng Functions**
- **EHRSystemSecure**: 10 functions (6 public, 2 view, 2 admin)
- **AccessControl**: 8 functions (2 write, 6 view)
- **RecordRegistry**: 11 functions (6 write, 5 view)
- **ConsentLedgerSecure**: 10 functions (6 write, 4 view)
- **DoctorUpdate**: 1 function (1 write)

**Tổng**: **40 functions** trong 5 contracts

### **Tính năng chính**
1. ✅ Role-based access control
2. ✅ Record management với parent-child relationship
3. ✅ Doctor-initiated record creation
4. ✅ Ownership claim mechanism
5. ✅ Consent management với EIP-712
6. ✅ Auto-grant consent
7. ✅ Delegate request/approve workflow
8. ✅ Emergency pause/unpause
9. ✅ Reentrancy protection
10. ✅ Expiration handling (vĩnh viễn support)

### **Use Cases được hỗ trợ**
- ✅ Patient tự tạo hồ sơ
- ✅ Doctor tạo hồ sơ cho patient
- ✅ Patient claim ownership từ doctor
- ✅ Doctor update hồ sơ với auto-grant
- ✅ Patient grant/revoke consent
- ✅ Doctor request delegate access
- ✅ Organization approve delegate access
- ✅ Delegate access cho doctor khác
- ✅ Emergency system pause

---

**Hệ thống đã hoàn chỉnh và sẵn sàng cho production! 🚀**


