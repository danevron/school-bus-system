import { Request, Response } from 'express';
import Registration, { RegistrationStatus } from '../models/Registration';
import RegistrationRequest from '../models/RegistrationRequest';
import User, { UserRole } from '../models/User';
import { validateCreateRegistrationRequest, validateUpdateRegistrationRequest } from '../utils/validation';

export const getActiveRegistrations = async (req: Request, res: Response): Promise<void> => {
  try {
    const activeRegistrations = await Registration.find({ status: RegistrationStatus.ACTIVE })
      .select('title description type stops activatedAt')
      .sort({ activatedAt: -1 });

    res.status(200).json({
      message: 'Active registrations retrieved successfully',
      data: { registrations: activeRegistrations }
    });
  } catch (error) {
    console.error('Error fetching active registrations:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const submitRegistrationRequest = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = validateCreateRegistrationRequest(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { registrationId } = req.params;
    const { student, address, selectedStop, comments } = req.body;

    // Check if registration exists and is active
    const registration = await Registration.findById(registrationId);
    if (!registration) {
      res.status(404).json({ message: 'Registration not found' });
      return;
    }

    if (registration.status !== RegistrationStatus.ACTIVE) {
      res.status(400).json({ message: 'Registration is not active' });
      return;
    }

    // Verify student exists and is actually a student
    const studentUser = await User.findById(student);
    if (!studentUser || studentUser.role !== UserRole.STUDENT) {
      res.status(404).json({ message: 'Student not found or invalid role' });
      return;
    }

    // Verify the student is a child of the requesting parent
    if (!studentUser.parents || !studentUser.parents.some(parentId => parentId.toString() === req.user?.userId)) {
      res.status(403).json({ message: 'You can only submit requests for your own children' });
      return;
    }

    // Validate that selected stop exists in the registration
    const stopExists = registration.stops.some(stop => stop.name === selectedStop.name);
    if (!stopExists) {
      res.status(400).json({ message: 'Selected stop is not available in this registration' });
      return;
    }

    // Check if request already exists for this student and registration
    const existingRequest = await RegistrationRequest.findOne({
      registration: registrationId,
      student: student
    });

    if (existingRequest) {
      res.status(400).json({ message: 'A request for this student already exists for this registration' });
      return;
    }

    // Create the registration request
    const registrationRequest = new RegistrationRequest({
      registration: registrationId,
      parent: req.user?.userId,
      student: student,
      address: address,
      selectedStop: selectedStop,
      comments: comments || undefined
    });

    await registrationRequest.save();
    await registrationRequest.populate([
      { path: 'registration', select: 'title type' },
      { path: 'parent', select: 'firstName lastName email phone' },
      { path: 'student', select: 'firstName lastName' }
    ]);

    res.status(201).json({
      message: 'Registration request submitted successfully',
      data: { request: registrationRequest }
    });
  } catch (error) {
    console.error('Error submitting registration request:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getMyRegistrationRequests = async (req: Request, res: Response): Promise<void> => {
  try {
    const requests = await RegistrationRequest.find({ parent: req.user?.userId })
      .populate([
        { path: 'registration', select: 'title type status' },
        { path: 'student', select: 'firstName lastName' }
      ])
      .sort({ createdAt: -1 });

    res.status(200).json({
      message: 'Your registration requests retrieved successfully',
      data: { requests }
    });
  } catch (error) {
    console.error('Error fetching user registration requests:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getAllRegistrationRequests = async (req: Request, res: Response): Promise<void> => {
  try {
    const { registrationId } = req.query;
    
    const filter: any = {};
    if (registrationId) filter.registration = registrationId;

    const requests = await RegistrationRequest.find(filter)
      .populate([
        { path: 'registration', select: 'title type status' },
        { path: 'parent', select: 'firstName lastName email phone' },
        { path: 'student', select: 'firstName lastName' }
      ])
      .sort({ createdAt: -1 });

    res.status(200).json({
      message: 'Registration requests retrieved successfully',
      data: { requests }
    });
  } catch (error) {
    console.error('Error fetching registration requests:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getRegistrationRequestById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    
    const request = await RegistrationRequest.findById(id)
      .populate([
        { path: 'registration', select: 'title type status stops' },
        { path: 'parent', select: 'firstName lastName email phone' },
        { path: 'student', select: 'firstName lastName' }
      ]);

    if (!request) {
      res.status(404).json({ message: 'Registration request not found' });
      return;
    }

    // Check authorization: only admin or the parent who submitted can view
    if (req.user?.role !== UserRole.ADMIN && request.parent._id.toString() !== req.user?.userId) {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    res.status(200).json({
      message: 'Registration request retrieved successfully',
      data: { request }
    });
  } catch (error) {
    console.error('Error fetching registration request:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateRegistrationRequest = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = validateUpdateRegistrationRequest(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { id } = req.params;
    const { student, address, selectedStop, comments } = req.body;

    const request = await RegistrationRequest.findById(id);
    if (!request) {
      res.status(404).json({ message: 'Registration request not found' });
      return;
    }

    // Check authorization: only the parent who submitted can update
    if (request.parent.toString() !== req.user?.userId) {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    // Check if the registration is still active
    const registration = await Registration.findById(request.registration);
    if (!registration || registration.status !== RegistrationStatus.ACTIVE) {
      res.status(400).json({ message: 'Cannot update request - registration is no longer active' });
      return;
    }

    // Update fields if provided
    if (student) {
      // Verify student exists and is actually a student
      const studentUser = await User.findById(student);
      if (!studentUser || studentUser.role !== UserRole.STUDENT) {
        res.status(404).json({ message: 'Student not found or invalid role' });
        return;
      }

      // Verify the student is a child of the requesting parent
      if (!studentUser.parents || !studentUser.parents.some(parentId => parentId.toString() === req.user?.userId)) {
        res.status(403).json({ message: 'You can only update requests for your own children' });
        return;
      }

      // Check if changing student would create duplicate
      if (student !== request.student.toString()) {
        const existingRequest = await RegistrationRequest.findOne({
          registration: request.registration,
          student: student
        });

        if (existingRequest) {
          res.status(400).json({ message: 'A request for this student already exists for this registration' });
          return;
        }
      }

      request.student = student;
    }

    if (address) {
      request.address = address;
    }

    if (selectedStop) {
      // Validate that selected stop exists in the registration
      const stopExists = registration.stops.some(stop => stop.name === selectedStop.name);
      if (!stopExists) {
        res.status(400).json({ message: 'Selected stop is not available in this registration' });
        return;
      }
      
      request.selectedStop = selectedStop;
    }

    if (comments !== undefined) {
      request.comments = comments || undefined;
    }

    await request.save();
    await request.populate([
      { path: 'registration', select: 'title type' },
      { path: 'parent', select: 'firstName lastName email phone' },
      { path: 'student', select: 'firstName lastName' }
    ]);

    res.status(200).json({
      message: 'Registration request updated successfully',
      data: { request }
    });
  } catch (error) {
    console.error('Error updating registration request:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const deleteRegistrationRequest = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const request = await RegistrationRequest.findById(id);
    if (!request) {
      res.status(404).json({ message: 'Registration request not found' });
      return;
    }

    // Check authorization: only admin or the parent who submitted can delete
    if (req.user?.role !== UserRole.ADMIN && request.parent.toString() !== req.user?.userId) {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    await RegistrationRequest.findByIdAndDelete(id);

    res.status(200).json({
      message: 'Registration request deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting registration request:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};