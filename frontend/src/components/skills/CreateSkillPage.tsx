import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Plus, X } from 'lucide-react';
import { skillService } from '../../services/skillService';
import { SkillFormData } from '../../types';
import toast from 'react-hot-toast';

const CreateSkillPage: React.FC = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState<SkillFormData>({
    title: '',
    description: '',
    category: '',
    type: 'offer',
    level: 'beginner',
    duration: '',
    location: 'online',
    tags: [],
  });
  const [tagInput, setTagInput] = useState('');

  const categories = [
    'Technology', 'Language', 'Music', 'Art', 'Cooking', 
    'Fitness', 'Business', 'Education', 'Crafts', 'Other'
  ];

  const levels = ['beginner', 'intermediate', 'advanced'];
  const locations = ['online', 'in-person', 'both'];
  const types = ['offer', 'request'];

  const handleInputChange = (field: keyof SkillFormData, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleAddTag = () => {
    if (tagInput.trim() && !formData.tags.includes(tagInput.trim())) {
      setFormData(prev => ({
        ...prev,
        tags: [...prev.tags, tagInput.trim()]
      }));
      setTagInput('');
    }
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setFormData(prev => ({
      ...prev,
      tags: prev.tags.filter(tag => tag !== tagToRemove)
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.title || !formData.description || !formData.category) {
      toast.error('Please fill in all required fields');
      return;
    }

    try {
      setLoading(true);
      console.log('📤 Sending skill data:', formData);
      await skillService.createSkill(formData);
      toast.success('Skill created successfully!');
      navigate('/my-skills');
    } catch (error: any) {
      console.log('❌ Skill creation error:', error);
      console.log('❌ Error response:', error.response?.data);
      // Handle validation errors with detailed messages
      if (error.response?.data?.details) {
        const validationErrors = error.response.data.details;
        const errorMessages = validationErrors.map((err: any) => err.msg).join(', ');
        toast.error(errorMessages);
      } else {
        const errorMessage = error.response?.data?.error || 'Failed to create skill';
        toast.error(errorMessage);
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      {/* Header */}
      <div className="flex items-center mb-6">
        <button
          onClick={() => navigate(-1)}
          className="mr-4 p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-full"
        >
          <ArrowLeft className="h-5 w-5" />
        </button>
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Create New Skill</h1>
          <p className="text-gray-600">Share what you can teach or what you'd like to learn</p>
        </div>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow p-6 space-y-6">
        {/* Type Selection */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            I want to... *
          </label>
          <div className="grid grid-cols-2 gap-4">
            {types.map(type => (
              <button
                key={type}
                type="button"
                onClick={() => handleInputChange('type', type)}
                className={`p-4 border-2 rounded-lg text-center transition-colors ${
                  formData.type === type
                    ? 'border-primary-500 bg-primary-50 text-primary-700'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <div className="font-medium">
                  {type === 'offer' ? 'Offer to Teach' : 'Request to Learn'}
                </div>
                <div className="text-sm text-gray-500 mt-1">
                  {type === 'offer' 
                    ? 'Share your knowledge' 
                    : 'Find someone to teach you'
                  }
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Title */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Skill Title *
          </label>
          <input
            type="text"
            value={formData.title}
            onChange={(e) => handleInputChange('title', e.target.value)}
            placeholder="e.g., JavaScript Programming, Guitar Lessons, Spanish Conversation"
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            required
          />
        </div>

        {/* Category */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Category *
          </label>
          <select
            value={formData.category}
            onChange={(e) => handleInputChange('category', e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            required
          >
            <option value="">Select a category</option>
            {categories.map(category => (
              <option key={category} value={category}>{category}</option>
            ))}
          </select>
        </div>

        {/* Description */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Description *
          </label>
          <textarea
            value={formData.description}
            onChange={(e) => handleInputChange('description', e.target.value)}
            placeholder="Describe what you can teach or what you want to learn. Be specific about your experience level, teaching style, or learning goals."
            rows={4}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            required
          />
        </div>

        {/* Level and Location */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Skill Level
            </label>
            <select
              value={formData.level}
              onChange={(e) => handleInputChange('level', e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            >
              {levels.map(level => (
                <option key={level} value={level}>
                  {level.charAt(0).toUpperCase() + level.slice(1)}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Location Preference
            </label>
            <select
              value={formData.location}
              onChange={(e) => handleInputChange('location', e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            >
              {locations.map(location => (
                <option key={location} value={location}>
                  {location.charAt(0).toUpperCase() + location.slice(1)}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Duration */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Duration (Optional)
          </label>
          <input
            type="text"
            value={formData.duration}
            onChange={(e) => handleInputChange('duration', e.target.value)}
            placeholder="e.g., 2 hours, 1 week, 30 minutes"
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
        </div>

        {/* Tags */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Tags (Optional)
          </label>
          <div className="flex gap-2 mb-2">
            <input
              type="text"
              value={tagInput}
              onChange={(e) => setTagInput(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddTag())}
              placeholder="Add a tag and press Enter"
              className="flex-1 border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
            <button
              type="button"
              onClick={handleAddTag}
              className="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700"
            >
              <Plus className="h-4 w-4" />
            </button>
          </div>
          {formData.tags.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {formData.tags.map(tag => (
                <span
                  key={tag}
                  className="inline-flex items-center px-3 py-1 rounded-full text-sm bg-primary-100 text-primary-800"
                >
                  {tag}
                  <button
                    type="button"
                    onClick={() => handleRemoveTag(tag)}
                    className="ml-2 text-primary-600 hover:text-primary-800"
                  >
                    <X className="h-3 w-3" />
                  </button>
                </span>
              ))}
            </div>
          )}
        </div>

        {/* Submit Button */}
        <div className="flex justify-end space-x-4 pt-6">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="px-6 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={loading}
            className="px-6 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? 'Creating...' : 'Create Skill'}
          </button>
        </div>
      </form>
    </div>
  );
};

export default CreateSkillPage;
