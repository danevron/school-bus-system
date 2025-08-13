import { Request, Response } from 'express';
import Vehicle from '../models/Vehicle';
import { vehicleValidation } from '../utils/validation';

export const createVehicle = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = vehicleValidation.create.validate(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const vehicle = new Vehicle(req.body);
    await vehicle.save();

    res.status(201).json({
      message: 'Vehicle created successfully',
      vehicle
    });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const getAllVehicles = async (req: Request, res: Response): Promise<void> => {
  try {
    const { isActive } = req.query;
    const filter: any = {};

    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }

    const vehicles = await Vehicle.find(filter);
    res.json({ vehicles });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const getVehicleById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const vehicle = await Vehicle.findById(id);
    if (!vehicle) {
      res.status(404).json({ message: 'Vehicle not found' });
      return;
    }

    res.json({ vehicle });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const updateVehicle = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { error } = vehicleValidation.update.validate(req.body);
    
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const vehicle = await Vehicle.findByIdAndUpdate(
      id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!vehicle) {
      res.status(404).json({ message: 'Vehicle not found' });
      return;
    }

    res.json({
      message: 'Vehicle updated successfully',
      vehicle
    });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const deleteVehicle = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const vehicle = await Vehicle.findByIdAndDelete(id);
    if (!vehicle) {
      res.status(404).json({ message: 'Vehicle not found' });
      return;
    }

    res.json({ message: 'Vehicle deleted successfully' });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
}; 