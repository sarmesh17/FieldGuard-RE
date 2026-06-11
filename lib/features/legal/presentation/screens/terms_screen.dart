import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

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
          'Terms & Conditions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: _LegalContent(),
      ),
    );
  }
}

class _LegalContent extends StatelessWidget {
  const _LegalContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(
          title: 'FieldGuard Terms and Conditions',
          subtitle: 'Effective Date: 31 May 2026\nLast Updated: 31 May 2026',
        ),
        const _Note(
          'These Terms and Conditions ("Terms") govern your use of the '
          'FieldGuard mobile application ("App") operated by your employer '
          '("Company") through the FieldGuard platform. By accessing or using '
          'the App, you confirm that you have read, understood, and agreed to '
          'be bound by these Terms, in accordance with the Electronic '
          'Transactions Act 2063 (2006) of Nepal.',
        ),
        const _Section(
          number: '1.',
          title: 'Eligibility and Authorised Use',
          body:
              'This App is exclusively for field employees authorised by their '
              'employer. Unauthorised access or use by any third party is strictly '
              'prohibited. You must:\n'
              '• Be an employee of a company registered on FieldGuard.\n'
              '• Use the App only for legitimate work-related purposes.\n'
              '• Not share your login credentials with any other person.\n'
              '• Notify your employer immediately if you suspect unauthorised '
              'access to your account.',
        ),
        const _Section(
          number: '2.',
          title: 'Location Tracking',
          body:
              'As part of your field duties, the App records your GPS location '
              'during active tracking sessions. This is conducted:\n'
              '• Solely during designated work hours or active task sessions.\n'
              '• For the purpose of route management, visit verification, and '
              'operational efficiency.\n'
              '• In compliance with the Labour Act 2074 BS (2017 AD) of Nepal '
              'and your employment agreement.\n\n'
              'Location tracking is initiated and terminated by you through the '
              'App. Continuous background tracking outside an active session '
              'does not occur without your action.',
        ),
        const _Section(
          number: '3.',
          title: 'Task and Payment Records',
          body:
              'All tasks assigned to you, visit records, payment collections, '
              'and related data entered in the App are the property of your '
              'employer. You are responsible for:\n'
              '• Accurately recording task outcomes and payment collections.\n'
              '• Ensuring that all information submitted is truthful and complete.\n'
              '• Compliance with your employer\'s internal policies.',
        ),
        const _Section(
          number: '4.',
          title: 'Your Obligations',
          body:
              'You agree to:\n'
              '• Use the App only for authorised business purposes.\n'
              '• Maintain the security of your login credentials.\n'
              '• Not attempt to reverse-engineer, copy, or tamper with the App.\n'
              '• Not use the App in any manner that violates applicable Nepal '
              'law, including the Electronic Transactions Act 2063 and the '
              'National Cyber Security Policy 2080.',
        ),
        const _Section(
          number: '5.',
          title: 'Intellectual Property',
          body:
              'All content, features, and functionality of the App — including '
              'software, design, text, and graphics — are the exclusive property '
              'of FieldGuard and are protected under Nepal\'s Copyright Act 2059 '
              '(2002 AD). You may not reproduce, distribute, or create derivative '
              'works without written permission.',
        ),
        const _Section(
          number: '6.',
          title: 'Limitation of Liability',
          body:
              'To the maximum extent permitted under Nepal law, FieldGuard and '
              'your employer shall not be liable for:\n'
              '• Indirect, incidental, or consequential damages arising from '
              'your use of the App.\n'
              '• Loss of data resulting from device failure, network outage, or '
              'circumstances beyond our reasonable control.',
        ),
        const _Section(
          number: '7.',
          title: 'Modification of Terms',
          body:
              'We reserve the right to update these Terms at any time. The '
              'revised Terms will be published in the App with a new effective '
              'date. Your continued use of the App after such changes constitutes '
              'acceptance of the updated Terms, consistent with the Electronic '
              'Transactions Act 2063.',
        ),
        const _Section(
          number: '8.',
          title: 'Governing Law and Dispute Resolution',
          body:
              'These Terms are governed by and construed in accordance with the '
              'laws of Nepal, including but not limited to:\n'
              '• Labour Act 2074 BS (2017 AD)\n'
              '• Electronic Transactions Act 2063 BS (2006 AD)\n'
              '• Company Act 2063 BS (2006 AD)\n\n'
              'Any disputes shall be resolved through the courts of competent '
              'jurisdiction in Nepal.',
        ),
        const _Section(
          number: '9.',
          title: 'Termination',
          body:
              'Your access to the App may be terminated by your employer at any '
              'time, consistent with your employment contract and the Labour Act '
              '2074. Upon termination, you must cease all use of the App '
              'immediately.',
        ),
        const _Section(
          number: '10.',
          title: 'Contact',
          body:
              'For questions regarding these Terms, please contact your company '
              'administrator or write to:\n'
              'FieldGuard Support\n'
              'Email: support@fieldguard.com',
        ),
        const SizedBox(height: 16),
        const _Footer(
          'By tapping "I have read and agree", you confirm that you have read '
          'these Terms in full and consent to be legally bound by them.',
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
