import { useState, useEffect } from 'react';
import { ProfileSetup } from './components/ProfileSetup';
import { Home } from './components/Home';
import { PartySession } from './components/PartySession';
import { EquipmentSession } from './components/EquipmentSession';
import { WorkflowSession } from './components/WorkflowSession';
import { ReviewSession } from './components/ReviewSession';
import { ExportSession } from './components/ExportSession';
import { Diagnostics } from './components/Diagnostics';

export type FormType = 'received' | 'returned' | 'replaced';
export type AppScreen = 'profile' | 'home' | 'party' | 'equipment' | 'workflow' | 'review' | 'export' | 'diagnostics';

export interface ProfileData {
  name: string;
  department: string;
  defaultLocation: string;
}

export interface PartyData {
  requestedBy: { name: string; department: string; email: string; };
  preparedBy: { name: string; department: string; email: string; };
  receivedBy: { name: string; department: string; email: string; };
  returnedBy: { name: string; department: string; email: string; };
}

export interface EquipmentData {
  devices: Array<{
    id: string;
    type: 'laptop' | 'phone' | 'accessory';
    make?: string;
    model?: string;
    assetTag?: string;
    serviceTag?: string;
    imei?: string;
    serial?: string;
    warrantyExpiry?: string;
    name?: string; // for accessories
  }>;
}

export interface WorkflowData {
  formType: FormType;
  dateReceived?: string;
  dateReturned?: string;
  dataHandlingConfirmed: boolean;
  location: string;
}

export interface FormData {
  profile: ProfileData;
  party: PartyData;
  equipment: EquipmentData;
  workflow: WorkflowData;
}

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<AppScreen>('profile');
  const [formType, setFormType] = useState<FormType>('received');
  const [profile, setProfile] = useState<ProfileData | null>(null);
  const [formData, setFormData] = useState<Partial<FormData>>({});

  // Load profile from localStorage on mount
  useEffect(() => {
    const savedProfile = localStorage.getItem('tullow-equipment-profile');
    if (savedProfile) {
      try {
        const profileData = JSON.parse(savedProfile);
        setProfile(profileData);
        setCurrentScreen('home');
      } catch (error) {
        console.error('Error loading profile:', error);
      }
    }
  }, []);

  // Save profile to localStorage
  const handleProfileComplete = (profileData: ProfileData) => {
    setProfile(profileData);
    setFormData(prev => ({ ...prev, profile: profileData }));
    localStorage.setItem('tullow-equipment-profile', JSON.stringify(profileData));
    setCurrentScreen('home');
  };

  const handleFormTypeSelect = (type: FormType) => {
    setFormType(type);
    setFormData(prev => ({ 
      ...prev, 
      workflow: { 
        ...prev.workflow, 
        formType: type,
        location: profile?.defaultLocation || 'ACC',
        dataHandlingConfirmed: false
      } 
    }));
    setCurrentScreen('party');
  };

  const handlePartyComplete = (partyData: PartyData) => {
    setFormData(prev => ({ ...prev, party: partyData }));
    setCurrentScreen('equipment');
  };

  const handleEquipmentComplete = (equipmentData: EquipmentData) => {
    setFormData(prev => ({ ...prev, equipment: equipmentData }));
    setCurrentScreen('workflow');
  };

  const handleWorkflowComplete = (workflowData: WorkflowData) => {
    setFormData(prev => ({ ...prev, workflow: workflowData }));
    setCurrentScreen('review');
  };

  const handleReviewComplete = () => {
    setCurrentScreen('export');
  };

  const handleExportComplete = () => {
    // Reset form data and go back to home
    setFormData({});
    setCurrentScreen('home');
  };

  const handleBackToHome = () => {
    setFormData({});
    setCurrentScreen('home');
  };

  const handleEditProfile = () => {
    setCurrentScreen('profile');
  };

  const handleShowDiagnostics = () => {
    setCurrentScreen('diagnostics');
  };

  if (!profile && currentScreen !== 'profile') {
    return (
      <ProfileSetup 
        onComplete={handleProfileComplete}
      />
    );
  }

  switch (currentScreen) {
    case 'profile':
      return (
        <ProfileSetup 
          onComplete={handleProfileComplete}
          initialData={profile || undefined}
        />
      );

    case 'home':
      return (
        <Home
          onFormTypeSelect={handleFormTypeSelect}
          onProfileEdit={handleEditProfile}
          onShowDiagnostics={handleShowDiagnostics}
          profileName={profile?.name || 'User'}
        />
      );

    case 'party':
      return (
        <PartySession
          formType={formType}
          profile={profile!}
          onComplete={handlePartyComplete}
          onBack={handleBackToHome}
          initialData={formData.party}
        />
      );

    case 'equipment':
      return (
        <EquipmentSession
          formType={formType}
          onComplete={handleEquipmentComplete}
          onBack={() => setCurrentScreen('party')}
          initialData={formData.equipment}
        />
      );

    case 'workflow':
      return (
        <WorkflowSession
          formType={formType}
          profile={profile!}
          onComplete={handleWorkflowComplete}
          onBack={() => setCurrentScreen('equipment')}
          initialData={formData.workflow}
        />
      );

    case 'review':
      return (
        <ReviewSession
          formType={formType}
          formData={formData as FormData}
          onComplete={handleReviewComplete}
          onBack={() => setCurrentScreen('workflow')}
          onEdit={(section) => setCurrentScreen(section as AppScreen)}
        />
      );

    case 'export':
      return (
        <ExportSession
          formType={formType}
          formData={formData as FormData}
          onComplete={handleExportComplete}
          onBack={() => setCurrentScreen('review')}
        />
      );

    case 'diagnostics':
      return (
        <Diagnostics
          onBack={handleBackToHome}
        />
      );

    default:
      return (
        <Home
          onFormTypeSelect={handleFormTypeSelect}
          onProfileEdit={handleEditProfile}
          onShowDiagnostics={handleShowDiagnostics}
          profileName={profile?.name || 'User'}
        />
      );
  }
}