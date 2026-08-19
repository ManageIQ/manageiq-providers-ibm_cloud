export type { Dispatch, SetStateAction } from "react";
export type {
  MiqFormSchemaType,
  SchemaField,
  OptionType,
  FormOptions
} from "@@miq-types/forms";

type SupportedProvidersType = {
  title: string;
  type: string;
  kind: string;
  regions?: Array<{
    name: string;
    description?: string;
  }>;
};

export type ProvidersResponse = {
  data: {
    supported_providers: SupportedProvidersType[];
  };
};

type ResourceType = {
  href: string;
  id: string;
  name: string;
  type: string;
};

export type ResourcesResponseType = {
  resources: ResourceType[];
};

export type FormState = {
  provider_type?: string;
  src_provider_id?: string;
  obj_storage_id?: string;
};

export type FormValues = {
  provider_type?: string;
  src_provider_id?: string;
  src_image_id?: string;
  obj_storage_id?: string;
  obj_storage_id_cos?: string;
  bucket_id?: string;
  bucket_id_cos?: string;
  disk_type_id?: string;
  disk_type_id_cos?: string;
  timeout?: number;
  timeout_cos?: number;
  keep_ova?: boolean;
  keep_ova_cos?: boolean;
};
