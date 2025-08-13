import { Request, Response } from 'express';
import Route from '../models/Route';
import { routeValidation } from '../utils/validation';

export const createRoute = async (req: Request, res: Response): Promise<void> => {
  try {
    const { error } = routeValidation.create.validate(req.body);
    if (error) {
      res.status(400).json({ message: error.details[0].message });
      return;
    }

    const route = new Route(req.body);
    await route.save();

    res.status(201).json({
      message: 'Route created successfully',
      route
    });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const getAllRoutes = async (req: Request, res: Response): Promise<void> => {
  try {
    const { isActive } = req.query;
    const filter: any = {};

    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }

    const routes = await Route.find(filter);
    res.json({ routes });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const getRouteById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const route = await Route.findById(id);
    if (!route) {
      res.status(404).json({ message: 'Route not found' });
      return;
    }

    res.json({ route });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const updateRoute = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const route = await Route.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!route) {
      res.status(404).json({ message: 'Route not found' });
      return;
    }

    res.json({
      message: 'Route updated successfully',
      route
    });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
};

export const deleteRoute = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const route = await Route.findByIdAndDelete(id);
    if (!route) {
      res.status(404).json({ message: 'Route not found' });
      return;
    }

    res.json({ message: 'Route deleted successfully' });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    res.status(500).json({ message: 'Server error', error: errMsg });
  }
}; 