import { Request, Response } from 'express';
import DeviceToken from '../models/DeviceToken';
import { log } from '../utils/logger';

export const registerToken = async (req: Request, res: Response): Promise<void> => {
  try {
    const { fcmToken, deviceId, platform } = req.body;
    const userId = req.user?.userId;

    if (!fcmToken) {
      res.status(400).json({ message: 'FCM token is required' });
      return;
    }

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    // Check if this exact token already exists for this user
    const existingToken = await DeviceToken.findOne({ 
      userId, 
      fcmToken,
      isActive: true 
    });

    if (existingToken) {
      // Update last used timestamp
      existingToken.lastUsed = new Date();
      await existingToken.save();
      
      res.status(200).json({ 
        message: 'Token already registered and updated',
        deviceToken: existingToken 
      });
      return;
    }

    // Check if token exists for different user - mark as inactive
    const tokenFromOtherUser = await DeviceToken.findOne({ fcmToken });
    if (tokenFromOtherUser) {
      tokenFromOtherUser.isActive = false;
      await tokenFromOtherUser.save();
      log.info('Deactivated token from user and attaching to new user', { fcmToken, previousUser: tokenFromOtherUser.userId, newUser: userId });
    }

    // If deviceId provided, deactivate any existing tokens for this user-device combination
    if (deviceId) {
      await DeviceToken.updateMany(
        { userId, deviceId, isActive: true },
        { isActive: false }
      );
    }

    // Create new device token
    const deviceToken = new DeviceToken({
      userId,
      fcmToken,
      deviceId,
      platform: platform || 'ios', // Default to iOS if not specified
      isActive: true,
      lastUsed: new Date()
    });

    await deviceToken.save();

    log.info('Registered FCM token', { userId, deviceId, platform });

    res.status(201).json({
      message: 'FCM token registered successfully',
      deviceToken: {
        id: deviceToken._id,
        platform: deviceToken.platform,
        isActive: deviceToken.isActive,
        createdAt: deviceToken.createdAt
      }
    });

  } catch (error) {
    log.error('Error registering FCM token', { error });
    res.status(500).json({ message: 'Error registering FCM token' });
  }
};

export const getUserTokens = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    const tokens = await DeviceToken.find({ 
      userId, 
      isActive: true 
    }).select('platform deviceId lastUsed createdAt');

    res.status(200).json({
      message: 'User tokens retrieved successfully',
      data: { tokens }
    });

  } catch (error) {
    log.error('Error retrieving user tokens', { error });
    res.status(500).json({ message: 'Error retrieving user tokens' });
  }
};

export const deactivateToken = async (req: Request, res: Response): Promise<void> => {
  try {
    const { fcmToken } = req.body;
    const userId = req.user?.userId;

    if (!fcmToken) {
      res.status(400).json({ message: 'FCM token is required' });
      return;
    }

    if (!userId) {
      res.status(401).json({ message: 'User not authenticated' });
      return;
    }

    const result = await DeviceToken.updateOne(
      { userId, fcmToken, isActive: true },
      { isActive: false }
    );

    if (result.modifiedCount === 0) {
      res.status(404).json({ message: 'Token not found or already inactive' });
      return;
    }

    log.info('Deactivated FCM token', { userId });

    res.status(200).json({
      message: 'FCM token deactivated successfully'
    });

  } catch (error) {
    log.error('Error deactivating FCM token', { error });
    res.status(500).json({ message: 'Error deactivating FCM token' });
  }
};