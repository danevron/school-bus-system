import { Request, Response } from 'express';
import Line from '../models/Line';
import User from '../models/User';
import Vehicle from '../models/Vehicle';
import { lineValidation } from '../utils/validation';
import { UserRole } from '../models/User';

export const createLine = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = lineValidation.create.validate(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { driver, vehicle, ...lineData } = req.body;

    // Verify driver exists and is a driver
    const driverUser = await User.findById(driver);
    if (!driverUser || driverUser.role !== UserRole.DRIVER) {
      res.status(404).json({ message: 'Driver not found or invalid role' });
      return;
    }

    // Verify vehicle exists
    const vehicleExists = await Vehicle.findById(vehicle);
    if (!vehicleExists) {
      res.status(404).json({ message: 'Vehicle not found' });
      return;
    }

    // Set max capacity from vehicle
    lineData.maxCapacity = vehicleExists.capacity;

    const line = new Line({
      ...lineData,
      driver,
      vehicle,
      students: [], // Initialize with empty students array
      route: {
        name: `${lineData.name} Route`,
        stops: [],
        totalDistance: 0,
        estimatedDuration: 0
      }
    });

    await line.save();

    const populatedLine = await line.populate([
      { path: 'driver', select: 'firstName lastName email' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email' }
    ]);

    res.status(201).json({
      message: 'Line created successfully',
      line: populatedLine
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getAllLines = async (req: Request, res: Response): Promise<void> => {
  try {
    const { isActive, driver } = req.query;
    const filter: any = {};

    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }

    if (driver) {
      filter.driver = driver;
    }

    const lines = await Line.find(filter).populate([
      { path: 'driver', select: 'firstName lastName email' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email' }
    ]);

    res.json({ lines });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getLineById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const line = await Line.findById(id).populate([
      { path: 'driver', select: 'firstName lastName email phone' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email phone' }
    ]);

    if (!line) {
      res.status(404).json({ message: 'Line not found' });
      return;
    }

    res.json({ line });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const updateLine = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    // Remove fields that shouldn't be updated directly
    delete updateData.route;
    delete updateData.driver;
    delete updateData.vehicle;
    delete updateData.students; // Students should be managed separately

    const line = await Line.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    ).populate([
      { path: 'route', select: 'name description' },
      { path: 'driver', select: 'firstName lastName email' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email' }
    ]);

    if (!line) {
      res.status(404).json({ message: 'Line not found' });
      return;
    }

    res.json({
      message: 'Line updated successfully',
      line
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const deleteLine = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const line = await Line.findByIdAndDelete(id);
    if (!line) {
      res.status(404).json({ message: 'Line not found' });
      return;
    }

    res.json({ message: 'Line deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getLinesByDriver = async (req: Request, res: Response): Promise<void> => {
  try {
    const driverId = req.user?.userId;

    const lines = await Line.find({ driver: driverId, isActive: true }).populate([
      { path: 'route', select: 'name description stops' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email' }
    ]);

    res.json({ lines });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const assignStudentsToLine = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { error } = lineValidation.assignStudents.validate(req.body);
    
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { students } = req.body;

    // Verify all students exist and are actually students
    const studentUsers = await User.find({
      _id: { $in: students },
      role: UserRole.STUDENT
    });

    if (studentUsers.length !== students.length) {
      res.status(400).json({ message: 'Some students not found or invalid role' });
      return;
    }

    // Get the line to check capacity
    const line = await Line.findById(id);
    if (!line) {
      res.status(404).json({ message: 'Line not found' });
      return;
    }

    // Check if assigning these students would exceed capacity
    if (students.length > line.maxCapacity) {
      res.status(400).json({ 
        message: `Cannot assign ${students.length} students. Line capacity is ${line.maxCapacity}` 
      });
      return;
    }

    // Update the line with new student assignments
    const updatedLine = await Line.findByIdAndUpdate(
      id,
      { students },
      { new: true, runValidators: true }
    ).populate([
      { path: 'route', select: 'name description' },
      { path: 'driver', select: 'firstName lastName email' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email' }
    ]);

    res.json({
      message: 'Students assigned to line successfully',
      line: updatedLine
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const addStudentToLine = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { studentId } = req.body;

    if (!studentId) {
      res.status(400).json({ message: 'Student ID is required' });
      return;
    }

    // Verify student exists and is actually a student
    const student = await User.findOne({
      _id: studentId,
      role: UserRole.STUDENT
    });

    if (!student) {
      res.status(404).json({ message: 'Student not found or invalid role' });
      return;
    }

    // Get the line to check capacity
    const line = await Line.findById(id);
    if (!line) {
      res.status(404).json({ message: 'Line not found' });
      return;
    }

    // Check if student is already assigned
    if (line.students.includes(studentId)) {
      res.status(400).json({ message: 'Student is already assigned to this line' });
      return;
    }

    // Check if adding this student would exceed capacity
    if (line.students.length >= line.maxCapacity) {
      res.status(400).json({ message: 'Line is at full capacity' });
      return;
    }

    // Add student to line
    const updatedLine = await Line.findByIdAndUpdate(
      id,
      { $addToSet: { students: studentId } },
      { new: true, runValidators: true }
    ).populate([
      { path: 'route', select: 'name description' },
      { path: 'driver', select: 'firstName lastName email' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email' }
    ]);

    res.json({
      message: 'Student added to line successfully',
      line: updatedLine
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const removeStudentFromLine = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id, studentId } = req.params;

    // Get the line
    const line = await Line.findById(id);
    if (!line) {
      res.status(404).json({ message: 'Line not found' });
      return;
    }

    // Check if student is assigned to this line
    if (!line.students.includes(studentId as any)) {
      res.status(400).json({ message: 'Student is not assigned to this line' });
      return;
    }

    // Remove student from line
    const updatedLine = await Line.findByIdAndUpdate(
      id,
      { $pull: { students: studentId } },
      { new: true, runValidators: true }
    ).populate([
      { path: 'driver', select: 'firstName lastName email' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email' }
    ]);

    res.json({
      message: 'Student removed from line successfully',
      line: updatedLine
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Route Management Endpoints (formerly in routeController)
export const updateLineRoute = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    
    // Validate route data
    const { error } = lineValidation.updateRoute.validate(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { name, stops, totalDistance, estimatedDuration } = req.body;

    const line = await Line.findById(id);
    if (!line) {
      res.status(404).json({ message: 'Line not found' });
      return;
    }

    // Update or create route data
    line.route = {
      name,
      stops,
      totalDistance,
      estimatedDuration
    };

    await line.save();

    const populatedLine = await line.populate([
      { path: 'driver', select: 'firstName lastName email phone' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email phone' }
    ]);

    res.json({
      message: 'Line route updated successfully',
      line: populatedLine
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const removeLineRoute = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const line = await Line.findById(id);
    if (!line) {
      res.status(404).json({ message: 'Line not found' });
      return;
    }

    // Remove route data
    line.route = undefined;
    await line.save();

    const populatedLine = await line.populate([
      { path: 'driver', select: 'firstName lastName email phone' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email phone' }
    ]);

    res.json({
      message: 'Line route removed successfully',
      line: populatedLine
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Stop Management Functions (formerly in routeController)
export const addStopToLineRoute = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    // Validate stop data
    const { error } = lineValidation.addStop.validate(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { stop } = req.body;

    const line = await Line.findById(id);
    if (!line) {
      res.status(404).json({ message: 'Line not found' });
      return;
    }

    if (!line.route) {
      res.status(400).json({ message: 'Line has no route. Please create a route first.' });
      return;
    }

    // Generate unique stopId for the new stop
    const stopWithId = {
      ...stop,
      stopId: `stop_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    };

    line.route.stops.push(stopWithId);
    await line.save();

    const populatedLine = await line.populate([
      { path: 'driver', select: 'firstName lastName email phone' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email phone' }
    ]);

    res.status(201).json({
      message: 'Stop added successfully',
      line: populatedLine
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const updateLineRouteStops = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    // Validate stops data
    const { error } = lineValidation.updateStops.validate(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const { stops } = req.body;

    const line = await Line.findById(id);
    if (!line) {
      res.status(404).json({ message: 'Line not found' });
      return;
    }

    if (!line.route) {
      res.status(400).json({ message: 'Line has no route. Please create a route first.' });
      return;
    }

    // Ensure all stops have stopId (for backward compatibility)
    const stopsWithIds = stops.map((stop: any) => ({
      ...stop,
      stopId: stop.stopId || `stop_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    }));

    line.route.stops = stopsWithIds;
    await line.save();

    const populatedLine = await line.populate([
      { path: 'driver', select: 'firstName lastName email phone' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email phone' }
    ]);

    res.json({
      message: 'Line route stops updated successfully',
      line: populatedLine
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const deleteStopFromLineRoute = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id, stopIndex } = req.params;

    const line = await Line.findById(id);
    if (!line) {
      res.status(404).json({ message: 'Line not found' });
      return;
    }

    if (!line.route) {
      res.status(400).json({ message: 'Line has no route. Please create a route first.' });
      return;
    }

    const index = parseInt(stopIndex);
    if (index < 0 || index >= line.route.stops.length) {
      res.status(400).json({ message: 'Invalid stop index' });
      return;
    }

    line.route.stops.splice(index, 1);
    await line.save();

    const populatedLine = await line.populate([
      { path: 'driver', select: 'firstName lastName email phone' },
      { path: 'vehicle', select: 'licensePlate make vehicleModel capacity' },
      { path: 'students', select: 'firstName lastName email phone' }
    ]);

    res.json({
      message: 'Stop deleted successfully',
      line: populatedLine
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
}; 