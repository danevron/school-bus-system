// Simple email service - in production, you would integrate with services like:
// SendGrid, AWS SES, Nodemailer with SMTP, etc.

export interface EmailOptions {
  to: string;
  subject: string;
  text: string;
  html?: string;
}

export class EmailService {
  /**
   * Send invitation email to user
   * For now, this just logs the email content - in production you'd send actual emails
   */
  static async sendInvitation(
    email: string, 
    inviterName: string, 
    role: string, 
    invitationToken: string
  ): Promise<boolean> {
    const invitationUrl = `${process.env.FRONTEND_URL || 'http://localhost:5173'}/accept-invitation?token=${invitationToken}`;
    
    const emailContent = {
      to: email,
      subject: 'School Bus System - You\'re Invited!',
      text: `
Hello!

You have been invited to join the School Bus Management System by ${inviterName}.

Role: ${role.charAt(0).toUpperCase() + role.slice(1)}

To complete your registration, please click the link below:
${invitationUrl}

This invitation will expire in 7 days.

If you have any questions, please contact your system administrator.

Best regards,
School Bus System Team
      `.trim(),
      html: `
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2 style="color: #007bff;">School Bus System - You're Invited!</h2>
  
  <p>Hello!</p>
  
  <p>You have been invited to join the School Bus Management System by <strong>${inviterName}</strong>.</p>
  
  <p><strong>Role:</strong> ${role.charAt(0).toUpperCase() + role.slice(1)}</p>
  
  <p>To complete your registration, please click the button below:</p>
  
  <div style="text-align: center; margin: 30px 0;">
    <a href="${invitationUrl}" 
       style="background-color: #007bff; color: white; padding: 12px 24px; 
              text-decoration: none; border-radius: 4px; display: inline-block;">
      Accept Invitation
    </a>
  </div>
  
  <p style="color: #666; font-size: 14px;">
    Or copy and paste this link in your browser:<br>
    <a href="${invitationUrl}">${invitationUrl}</a>
  </p>
  
  <p style="color: #666; font-size: 14px;">
    This invitation will expire in 7 days.
  </p>
  
  <p style="color: #666; font-size: 14px;">
    If you have any questions, please contact your system administrator.
  </p>
  
  <p>Best regards,<br>School Bus System Team</p>
</div>
      `.trim()
    };

    try {
      // In development/demo mode, just log the email
      console.log('\n=== EMAIL INVITATION ===');
      console.log(`To: ${emailContent.to}`);
      console.log(`Subject: ${emailContent.subject}`);
      console.log(`\n${emailContent.text}\n`);
      console.log('========================\n');
      
      // TODO: In production, replace this with actual email sending:
      // await this.sendEmail(emailContent);
      
      return true;
    } catch (error) {
      console.error('Failed to send invitation email:', error);
      return false;
    }
  }

  /**
   * Generic email sending method
   * In production, implement with your preferred email service
   */
  private static async sendEmail(options: EmailOptions): Promise<void> {
    // Example implementations:
    
    // Using SendGrid:
    // const msg = {
    //   to: options.to,
    //   from: 'noreply@schoolbus.com',
    //   subject: options.subject,
    //   text: options.text,
    //   html: options.html,
    // };
    // await sgMail.send(msg);
    
    // Using Nodemailer:
    // await transporter.sendMail({
    //   from: 'noreply@schoolbus.com',
    //   to: options.to,
    //   subject: options.subject,
    //   text: options.text,
    //   html: options.html,
    // });
    
    throw new Error('Email service not implemented');
  }
}