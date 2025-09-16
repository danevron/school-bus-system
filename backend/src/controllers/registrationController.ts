import { Request, Response } from 'express';
import Registration, { RegistrationStatus } from '../models/Registration';
import RegistrationRequest from '../models/RegistrationRequest';
import { validateCreateRegistration, validateUpdateRegistration } from '../utils/validation';

export const createRegistration = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = validateCreateRegistration(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { title, description, type, stops } = req.body;

    const registration = new Registration({
      title,
      description,
      type,
      stops,
      createdBy: req.user?.userId
    });

    await registration.save();
    await registration.populate('createdBy', 'firstName lastName email');

    res.status(201).json({
      message: 'Registration created successfully',
      data: { registration }
    });
  } catch (error) {
    console.error('Error creating registration:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getAllRegistrations = async (req: Request, res: Response): Promise<void> => {
  try {
    const { status, type } = req.query;
    
    const filter: any = {};
    if (status) filter.status = status;
    if (type) filter.type = type;

    const registrations = await Registration.find(filter)
      .populate('createdBy', 'firstName lastName email')
      .sort({ createdAt: -1 });

    res.status(200).json({
      message: 'Registrations retrieved successfully',
      data: { registrations }
    });
  } catch (error) {
    console.error('Error fetching registrations:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getRegistrationById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    
    const registration = await Registration.findById(id)
      .populate('createdBy', 'firstName lastName email');

    if (!registration) {
      res.status(404).json({ message: 'Registration not found' });
      return;
    }

    res.status(200).json({
      message: 'Registration retrieved successfully',
      data: { registration }
    });
  } catch (error) {
    console.error('Error fetching registration:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateRegistration = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = validateUpdateRegistration(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { id } = req.params;
    const { title, description, type, stops } = req.body;

    const registration = await Registration.findById(id);
    if (!registration) {
      res.status(404).json({ message: 'Registration not found' });
      return;
    }

    // Don't allow updates if registration is active or closed
    if (registration.status !== RegistrationStatus.DRAFT) {
      res.status(400).json({ message: 'Cannot update registration that is not in draft status' });
      return;
    }

    if (title) registration.title = title;
    if (description !== undefined) registration.description = description;
    if (type) registration.type = type;
    if (stops) registration.stops = stops;

    await registration.save();
    await registration.populate('createdBy', 'firstName lastName email');

    res.status(200).json({
      message: 'Registration updated successfully',
      data: { registration }
    });
  } catch (error) {
    console.error('Error updating registration:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const activateRegistration = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const registration = await Registration.findById(id);
    if (!registration) {
      res.status(404).json({ message: 'Registration not found' });
      return;
    }

    if (registration.status !== RegistrationStatus.DRAFT) {
      res.status(400).json({ message: 'Only draft registrations can be activated' });
      return;
    }

    registration.status = RegistrationStatus.ACTIVE;
    await registration.save();
    await registration.populate('createdBy', 'firstName lastName email');

    res.status(200).json({
      message: 'Registration activated successfully',
      data: { registration }
    });
  } catch (error) {
    console.error('Error activating registration:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const closeRegistration = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const registration = await Registration.findById(id);
    if (!registration) {
      res.status(404).json({ message: 'Registration not found' });
      return;
    }

    if (registration.status !== RegistrationStatus.ACTIVE) {
      res.status(400).json({ message: 'Only active registrations can be closed' });
      return;
    }

    registration.status = RegistrationStatus.CLOSED;
    await registration.save();
    await registration.populate('createdBy', 'firstName lastName email');

    res.status(200).json({
      message: 'Registration closed successfully',
      data: { registration }
    });
  } catch (error) {
    console.error('Error closing registration:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const deleteRegistration = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const registration = await Registration.findById(id);
    if (!registration) {
      res.status(404).json({ message: 'Registration not found' });
      return;
    }

    // Check if there are any registration requests
    const requestCount = await RegistrationRequest.countDocuments({ registration: id });
    if (requestCount > 0) {
      res.status(400).json({ message: 'Cannot delete registration with existing requests' });
      return;
    }

    await Registration.findByIdAndDelete(id);

    res.status(200).json({
      message: 'Registration deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting registration:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};