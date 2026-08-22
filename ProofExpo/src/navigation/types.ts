export type RootStackParamList = {
  MainTabs: undefined;
  CaptureProof: { resolutionId: string };
  CreateResolution: undefined;
  Progress: { resolutionId: string; friendId?: string };
  PartnerProof: { friendId: string };
};

export type MainTabParamList = {
  Today: undefined;
  Friends: undefined;
  Profile: undefined;
};
