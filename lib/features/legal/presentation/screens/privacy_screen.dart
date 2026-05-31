import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E4F),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: _PrivacyContent(),
      ),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(
          title: 'FieldGuard Privacy Policy',
          subtitle: 'Effective Date: 31 May 2026\nLast Updated: 31 May 2026',
        ),
        const _Note(
          'FieldGuard ("we", "our", or "the Platform") is committed to '
          'protecting the personal data of field employees in compliance with '
          'Nepal\'s Privacy Act 2075 BS (2018 AD) and applicable data '
          'protection principles. This Policy explains what data we collect, '
          'why we collect it, and how it is used and protected.',
        ),
        const _Section(
          number: '1.',
          title: 'Information We Collect',
          body:
              'When you use the FieldGuard App, we may collect the following '
              'categories of personal data:\n\n'
              'Identity & Contact Data\n'
              '• Full name, phone number, employee code, and profile photograph.\n\n'
              'Location Data\n'
              '• GPS coordinates, route history, and geofence entry/exit events '
              'recorded during active tracking sessions you initiate.\n\n'
              'Work & Operational Data\n'
              '• Task assignments, task status updates, visit logs, payment '
              'collections, shop visit history, and remarks you submit.\n\n'
              'Device & Usage Data\n'
              '• Device type, operating system version, app version, and '
              'session timestamps.\n\n'
              'Consent Records\n'
              '• Date and version of the Terms & Conditions and Privacy Policy '
              'you accepted, as required by the Electronic Transactions Act '
              '2063.',
        ),
        const _Section(
          number: '2.',
          title: 'How We Use Your Information',
          body:
              'Your personal data is used strictly for the following purposes:\n'
              '• Managing field operations, task assignments, and route planning.\n'
              '• Verifying shop visits and recording geofence-based attendance.\n'
              '• Processing and auditing cash and cheque payment collections.\n'
              '• Generating performance reports for your employer.\n'
              '• Sending transactional SMS notifications related to collections.\n'
              '• Maintaining security and detecting fraudulent activity.\n'
              '• Complying with Nepal tax and accounting regulations.',
        ),
        const _Section(
          number: '3.',
          title: 'Legal Basis for Processing (Privacy Act 2075)',
          body:
              'We process your personal data under the following legal bases '
              'recognised by Nepal\'s Privacy Act 2075 BS:\n\n'
              '(a) Contractual Necessity — processing is required to fulfil your '
              'employment obligations and provide the App services.\n\n'
              '(b) Legitimate Business Interest — operational management, '
              'performance tracking, and fraud prevention.\n\n'
              '(c) Your Consent — for GPS location tracking during active '
              'sessions. You may withdraw consent by stopping the tracking '
              'session at any time through the App.\n\n'
              '(d) Legal Obligation — retention of financial records for '
              'compliance with the Income Tax Act 2058 and VAT Act 2052.',
        ),
        const _Section(
          number: '4.',
          title: 'Data Sharing',
          body:
              'Your data may be shared with:\n'
              '• Your employer and authorised managers on the FieldGuard platform.\n'
              '• SMS gateway providers solely for sending transactional '
              'collection confirmations.\n'
              '• Cloud infrastructure providers (data stored on servers with '
              'industry-standard security).\n'
              '• Law enforcement or government authorities when required by a '
              'valid court order or Nepal law.\n\n'
              'We do not sell, rent, or trade your personal data to any third '
              'party for commercial purposes.',
        ),
        const _Section(
          number: '5.',
          title: 'Data Retention',
          body:
              'We retain your personal data only as long as necessary:\n'
              '• Active session & location data: 6 months from collection.\n'
              '• Task and visit records: 12 months from creation.\n'
              '• Payment and financial records: 7 years (Nepal income tax '
              'compliance requirement).\n'
              '• Account data: for the duration of your employment, then deleted '
              'within 90 days of account deactivation, unless legally required '
              'to retain it longer.',
        ),
        const _Section(
          number: '6.',
          title: 'Your Rights (Privacy Act 2075, Section 7)',
          body:
              'As a data subject under Nepal\'s Privacy Act 2075, you have the '
              'right to:\n'
              '• Access — request a copy of the personal data we hold about you.\n'
              '• Correction — request that inaccurate data be corrected.\n'
              '• Deletion — request deletion of data that is no longer necessary '
              '(subject to legal retention obligations).\n'
              '• Restriction — ask us to restrict processing in certain '
              'circumstances.\n'
              '• Complaint — lodge a complaint with the competent authority '
              'designated under Nepal\'s Privacy Act 2075.\n\n'
              'To exercise these rights, contact your employer\'s administrator '
              'or write to privacy@fieldguard.com.',
        ),
        const _Section(
          number: '7.',
          title: 'Data Security',
          body:
              'We implement appropriate technical and organisational measures to '
              'protect your personal data against unauthorised access, disclosure, '
              'alteration, or destruction, including:\n'
              '• Encrypted data transmission (HTTPS/TLS).\n'
              '• Secure token-based authentication (JWT).\n'
              '• Role-based access controls — your data is visible only to '
              'authorised personnel in your company.\n'
              '• Regular security reviews and infrastructure monitoring.',
        ),
        const _Section(
          number: '8.',
          title: 'Cookies and Analytics',
          body:
              'The FieldGuard mobile App does not use browser cookies. Limited '
              'anonymised usage analytics (app version, session count) may be '
              'collected to improve App stability. No personally identifiable '
              'information is included in analytics data.',
        ),
        const _Section(
          number: '9.',
          title: 'Changes to This Policy',
          body:
              'We may update this Privacy Policy to reflect changes in our '
              'practices or Nepal law. When we do, we will update the "Last '
              'Updated" date and, where required, request fresh consent through '
              'the App. Continued use of the App after changes constitutes '
              'acceptance of the revised Policy.',
        ),
        const _Section(
          number: '10.',
          title: 'Contact and Grievance',
          body:
              'For privacy-related queries, requests, or complaints:\n'
              'FieldGuard Privacy Team\n'
              'Email: privacy@fieldguard.com\n\n'
              'You may also contact the relevant government authority in Nepal '
              'responsible for personal data protection if you believe your '
              'rights under the Privacy Act 2075 have been violated.',
        ),
        const SizedBox(height: 16),
        const _Footer(
          'By using the FieldGuard App you acknowledge that you have read '
          'this Privacy Policy and consent to the collection and use of your '
          'information as described above.',
        ),
      ],
    );
  }
}

// ── Reusable layout widgets ───────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFE5E7EB)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1FADF)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF064E3B),
          height: 1.55,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  const _Section({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF157347),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final String text;
  const _Footer(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12.5,
          color: Color(0xFF6B7280),
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    );
  }
}
