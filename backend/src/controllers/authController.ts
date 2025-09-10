import { Request, Response } from 'express';
import User, { UserRole } from '../models/User';
import { generateToken } from '../utils/jwt';
import { userValidation, validateConnectStudentToParents } from '../utils/validation';
import { log } from '../utils/logger';
import mongoose from 'mongoose';

export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = userValidation.register.validate(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { email, password, firstName, lastName, phone, role } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      res.status(400).json({ message: 'User already exists' });
      return;
    }

    // Create new user
    const user = new User({
      email,
      password,
      firstName,
      lastName,
      phone,
      role
    });

    await user.save();

    // Generate token
    const token = generateToken(user);

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        id: user._id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role
      }
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = userValidation.login.validate(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { email, password } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      res.status(401).json({ message: 'Invalid credentials' });
      return;
    }

    // Check password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      res.status(401).json({ message: 'Invalid credentials' });
      return;
    }

    // Check if user is active
    if (!user.isActive) {
      res.status(401).json({ message: 'Account is deactivated' });
      return;
    }

    // Generate token
    const token = generateToken(user);

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role
      }
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getProfile = async (req: Request, res: Response): Promise<void> => {
  try {
    const user = await User.findById(req.user?.userId)
      .select('-password')
      .populate('children', 'firstName lastName role');
      
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    res.json({ user });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getAllUsers = async (req: Request, res: Response): Promise<void> => {
  try {
    const { role, isActive, populate } = req.query;
    
    const filter: any = {};
    if (role) filter.role = role;
    if (isActive !== undefined) filter.isActive = isActive === 'true';

    let query = User.find(filter).select('-password').sort({ createdAt: -1 });
    
    // Populate relationships if requested
    if (populate === 'true') {
      query = query
        .populate('parents', 'firstName lastName email phone')
        .populate('children', 'firstName lastName phone');
    }

    const users = await query;

    res.json({ users });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const createStudent = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = userValidation.createStudent.validate(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { firstName, lastName, phone } = req.body;

    // Create new student user without email/password
    const student = new User({
      firstName,
      lastName,
      phone,
      role: UserRole.STUDENT
    });

    await student.save();

    res.status(201).json({
      message: 'Student created successfully',
      user: {
        id: student._id,
        firstName: student.firstName,
        lastName: student.lastName,
        phone: student.phone,
        role: student.role
      }
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const connectStudentToParents = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = validateConnectStudentToParents(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { studentId, parentIds } = req.body;

    // Validate student exists and is a student
    const student = await User.findOne({ _id: studentId, role: UserRole.STUDENT });
    if (!student) {
      res.status(404).json({ message: 'Student not found' });
      return;
    }

    // Check if student already has 2 parents
    if (student.parents && student.parents.length >= 2) {
      res.status(400).json({ message: 'Student already has maximum number of parents (2)' });
      return;
    }

    // Validate all parents exist and are parents
    const parents = await User.find({ 
      _id: { $in: parentIds }, 
      role: UserRole.PARENT 
    });
    
    if (parents.length !== parentIds.length) {
      res.status(404).json({ message: 'One or more parents not found' });
      return;
    }

    // Check if adding these parents would exceed the limit
    const currentParentCount = student.parents?.length || 0;
    if (currentParentCount + parentIds.length > 2) {
      res.status(400).json({ message: 'Adding these parents would exceed maximum of 2 parents per student' });
      return;
    }

    // Check if any parent is already connected to this student
    const existingParents = student.parents || [];
    const duplicateParents = parentIds.filter((id: string) => 
      existingParents.some(parentId => parentId.toString() === id)
    );
    if (duplicateParents.length > 0) {
      res.status(400).json({ message: 'One or more parents are already connected to this student' });
      return;
    }

    // Update student's parents
    student.parents = [...existingParents, ...parentIds];
    log.info('Connecting student to parents', { 
      studentId, 
      parentIds, 
      totalParents: student.parents.length 
    });
    await student.save();

    // Update each parent's children
    for (const parent of parents) {
      if (!parent.children) {
        parent.children = [];
      }
      if (!parent.children.includes(studentId)) {
        parent.children.push(studentId);
        await parent.save();
      }
    }

    // Fetch updated data with populated relationships
    const updatedStudent = await User.findById(studentId)
      .populate('parents', 'firstName lastName email phone')
      .select('-password');

    res.status(200).json({
      message: 'Student connected to parents successfully',
      student: updatedStudent
    });

  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getStudentsWithParentInfo = async (req: Request, res: Response): Promise<void> => {
  try {
    const { maxParents } = req.query;
    
    const filter: any = { role: UserRole.STUDENT };
    if (maxParents) {
      const max = parseInt(maxParents as string);
      filter.$expr = {
        $lte: [{ $size: { $ifNull: ['$parents', []] } }, max]
      };
    }

    const students = await User.find(filter)
      .populate('parents', 'firstName lastName email phone')
      .select('-password')
      .sort({ createdAt: -1 });

    res.json({ students });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};