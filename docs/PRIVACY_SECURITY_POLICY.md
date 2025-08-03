# Mira Storyteller - Privacy & Security Policy

## Executive Summary

Mira Storyteller is a family-friendly AI storytelling application designed with privacy-by-design principles, specifically built for compliance with GDPR, COPPA, and other international children's privacy regulations.

## Core Privacy Principles

### 1. Privacy-by-Design Architecture
- **No Image Storage**: User-uploaded images are processed in-memory only and never stored on servers
- **Local Encryption**: All sensitive data stored locally using device-level encryption
- **Minimal Data Collection**: Only essential data required for service functionality
- **Family Data Isolation**: Technical measures ensure families cannot access each other's data

### 2. Data Processing Philosophy
```
Image Upload → Base64 Conversion → AI Processing → Story Generation → Audio Creation → Cleanup
```
- Images are immediately converted to base64 format
- Processed in server memory for AI analysis
- Original images deleted from memory after processing
- No persistent image storage anywhere in the system

## Technical Security Measures

### 1. Database Security (Supabase PostgreSQL)
- **Row Level Security (RLS)**: Database-level isolation between families
- **Encrypted at Rest**: All data encrypted using AES-256
- **Encrypted in Transit**: TLS 1.3 for all communications
- **Geographic Data Residency**: EU/US options available for GDPR compliance

### 2. Authentication & Access Control
```sql
-- Example RLS Policy: Families can only see their own data
CREATE POLICY family_isolation ON stories
    FOR ALL USING (family_id IN (
        SELECT family_id FROM user_profiles WHERE id = auth.uid()
    ));
```

### 3. Local Device Security
- **Flutter Secure Storage**: Biometric-protected local storage
- **Background Privacy**: App content hidden when backgrounded
- **Automatic Session Timeout**: Security sessions expire after inactivity

## GDPR Compliance Framework

### 1. Legal Basis for Processing
- **Consent**: Explicit consent for AI story generation
- **Legitimate Interest**: Service functionality and improvement
- **Parental Consent**: Required for children under 13 (COPPA) / 16 (GDPR)

### 2. Data Subject Rights Implementation
```typescript
// Technical implementation of GDPR rights
interface GDPRRights {
  // Right to Access (Article 15)
  exportUserData(familyId: string): Promise<UserDataExport>;
  
  // Right to Rectification (Article 16)
  updateUserProfile(userId: string, updates: ProfileUpdates): Promise<void>;
  
  // Right to Erasure (Article 17)
  deleteUserAccount(userId: string, reason: DeletionReason): Promise<void>;
  
  // Right to Data Portability (Article 20)
  exportPortableData(familyId: string): Promise<PortableDataPackage>;
  
  // Right to Object (Article 21)
  disableDataProcessing(userId: string, scope: ProcessingScope): Promise<void>;
}
```

### 3. Data Retention Policies
- **Active Stories**: Retained while family subscription is active
- **Inactive Accounts**: Automatically deleted after 12 months of inactivity
- **Audio Files**: Deleted from server after 30 days (available via local download)
- **Processing Logs**: Retained for 90 days for security monitoring

## Children's Privacy Protection (COPPA/GDPR Article 8)

### 1. Age Verification & Parental Consent
```typescript
interface ChildProtection {
  // Verifiable parental consent required
  requireParentalConsent(childAge: number): boolean;
  
  // Limited data collection for children
  getPermittedDataCollection(childAge: number): DataCollectionScope;
  
  // Enhanced security for children's profiles
  enableChildProtectionMode(childId: string): Promise<void>;
}
```

### 2. Content Safety Measures
- **AI Content Filtering**: All generated stories screened for age-appropriateness
- **Predefined Safe Prompts**: AI prompts designed for child-safe content generation
- **Parental Review Workflow**: Optional parent approval before story access
- **No User-Generated Content**: Eliminates risks from inappropriate user input

### 3. Data Minimization for Children
```sql
-- Children's profiles store minimal data only
CREATE TABLE child_profiles (
    id UUID PRIMARY KEY,
    family_id UUID NOT NULL,
    display_name VARCHAR(50) NOT NULL, -- First name only
    age_group VARCHAR(10) NOT NULL,    -- Age ranges, not exact age
    preferred_language VARCHAR(5) NOT NULL,
    -- NO: photos, full names, birth dates, locations
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Data Flow & Processing Transparency

### 1. Image Processing Pipeline
```
1. User uploads image via Flutter app
2. Image converted to base64 (local device)
3. Base64 sent to FastAPI backend
4. Gemini AI analyzes image (Google Cloud)
5. Image caption generated
6. Original base64 data discarded
7. Mistral AI generates story from caption
8. ElevenLabs creates audio narration
9. Story and audio returned to user
10. All temporary data cleaned from server memory
```

### 2. Data Storage Locations
- **User Profiles**: Supabase PostgreSQL (EU/US regions)
- **Generated Stories**: Supabase PostgreSQL with RLS
- **Audio Files**: Local device storage only (after initial generation)
- **Images**: Never stored - processed in memory only
- **AI Processing**: Temporary processing in AI provider clouds (Google, Mistral, ElevenLabs)

### 3. Third-Party Data Sharing
```yaml
AI_PROVIDERS:
  Google_Gemini:
    purpose: "Image analysis for story generation"
    data_shared: "Base64 image data (temporary)"
    retention: "Not retained - processed in real-time"
    location: "Google Cloud (EU/US options)"
    
  Mistral_AI:
    purpose: "Story text generation"
    data_shared: "Image captions only (no images)"
    retention: "Not retained - processed in real-time"
    location: "EU/US data centers"
    
  ElevenLabs:
    purpose: "Audio narration generation"
    data_shared: "Story text only"
    retention: "Not retained - processed in real-time"
    location: "Global edge locations"
```

## Security Incident Response Plan

### 1. Incident Classification
- **Level 1**: Minor security issue (e.g., failed login attempts)
- **Level 2**: Data exposure risk (e.g., configuration vulnerability)
- **Level 3**: Confirmed data breach affecting user data

### 2. Response Timeline
- **0-1 hours**: Incident detection and containment
- **1-4 hours**: Impact assessment and stakeholder notification
- **4-24 hours**: System remediation and security patches
- **72 hours**: GDPR breach notification (if applicable)
- **30 days**: Post-incident review and policy updates

### 3. User Notification Process
```typescript
interface IncidentNotification {
  notifyAffectedUsers(incident: SecurityIncident): Promise<void>;
  provideRemediation(userIds: string[]): Promise<void>;
  offerDataExport(userIds: string[]): Promise<void>;
  enableEnhancedSecurity(userIds: string[]): Promise<void>;
}
```

## Regulatory Compliance Matrix

| Regulation | Status | Implementation |
|------------|--------|----------------|
| **GDPR (EU)** | ✅ Compliant | RLS policies, data minimization, user rights |
| **COPPA (US)** | ✅ Compliant | Parental consent, age verification, data limits |
| **PIPEDA (Canada)** | ✅ Compliant | Privacy-by-design, consent mechanisms |
| **LGPD (Brazil)** | ✅ Compliant | Data protection impact assessment |
| **Privacy Act (Australia)** | ✅ Compliant | Privacy policy, breach notification |

## Technical Audit & Monitoring

### 1. Automated Security Monitoring
```sql
-- Security audit log table
CREATE TABLE security_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(50) NOT NULL,
    user_id UUID,
    family_id UUID,
    ip_address INET,
    user_agent TEXT,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Monitor for suspicious activity
CREATE OR REPLACE FUNCTION log_security_event()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO security_audit_log (event_type, user_id, details)
    VALUES (TG_OP, NEW.id, row_to_json(NEW));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 2. Privacy Impact Assessments
- **Quarterly Privacy Reviews**: Systematic assessment of data flows
- **AI Model Audits**: Regular review of AI-generated content safety
- **Third-Party Assessments**: Annual security audits by external firms
- **Penetration Testing**: Bi-annual security testing

## Data Protection Officer (DPO) Responsibilities

### 1. Privacy Oversight
- Monitor GDPR compliance implementation
- Conduct privacy impact assessments
- Handle data subject requests
- Liaise with supervisory authorities

### 2. Contact Information
```
Data Protection Officer
Mira Storyteller
Email: privacy@mirastoryteller.com
Response Time: 48 hours for privacy requests
GDPR Representative (EU): [To be appointed]
```

## User Rights & Procedures

### 1. Data Access Requests
Users can request their data through:
- In-app privacy dashboard
- Email to privacy@mirastoryteller.com
- Automated data export functionality

### 2. Data Deletion Procedures
```typescript
// Complete account deletion process
async function deleteUserAccount(userId: string) {
  // 1. Verify user identity
  await verifyUserIdentity(userId);
  
  // 2. Export data (if requested)
  if (userWantsExport) {
    await exportUserData(userId);
  }
  
  // 3. Delete all user data
  await deleteUserProfiles(userId);
  await deleteUserStories(userId);
  await deleteAudioFiles(userId);
  await anonymizeAuditLogs(userId);
  
  // 4. Confirm deletion
  await sendDeletionConfirmation(userId);
}
```

## Future Compliance Considerations

### 1. Emerging Regulations
- **EU AI Act**: Monitoring for AI system requirements
- **UK Age-Appropriate Design Code**: Additional children's privacy protections
- **California CPRA**: Enhanced privacy rights for California residents

### 2. Technical Roadmap
- **Zero-Knowledge Architecture**: Investigate end-to-end encryption options
- **Federated Learning**: Explore local AI processing to eliminate data sharing
- **Blockchain Verification**: Consider immutable audit trails for compliance

---

**Document Version**: 1.0  
**Last Updated**: 2025-06-27  
**Next Review**: 2025-09-27  
**Approved By**: [To be completed]  
**Legal Review**: [To be completed]

---

*This document is a living policy that will be updated as regulations evolve and new privacy-enhancing technologies become available.*