import React from 'react';
import { componentTypes, validatorTypes } from '@@ddf';


const createSchema = (providers, provider, setProvider, images, image, setImage, storages, storage, setStorage, buckets, bucket, setBucket, diskTypes, setDiskType, keepOva, setKeepOva) => ({
  fields: [
    {
      component: componentTypes.SELECT,
      name:"src_provider_id",
      id:"src_provider_id",
      initializeOnMount: true,
      isRequired: true,
      label: "Choose source provider",
      loadOptions: () => providers,
      onChange: (value) => {setProvider(value); setImage('-1')},
    },

    {
      component: componentTypes.SELECT,
      name: "src_image_id",
      id:"src_image_id",
      key: `provider-key-${provider}`,
      initializeOnMount: true,
      isRequired: true,
      label: "Choose source image",
      loadOptions: () => images,
      onChange: (value) => {setImage(value)},
    },

    {
      component: componentTypes.SELECT,
      name:"storage_id",
      id:"storage_id",
      initializeOnMount: true,
      isRequired: true,
      label: "Choose object storage",
      loadOptions: () => storages,
      onChange: (value) => {setStorage(value); setBucket('-1')},
    },

    {
      component: componentTypes.SELECT,
      name: "bucket_id",
      id:"bucket_id",
      key: `storage-key-${storage}`,
      initializeOnMount: true,
      isRequired: true,
      label: "Choose cloud bucket",
      loadOptions: () => buckets,
      onChange: (value) => {setBucket(value)},
    },

    {
      component: componentTypes.SELECT,
      name: "diskType_id",
      id:"diskType_id",
      initializeOnMount: true,
      isRequired: true,
      label: "Choose Disk Type",
      loadOptions: () => diskTypes,
      onChange: (value) => {setDiskType(value)},
    },

    {
      component: 'checkbox',
      name: "keep_ova",
      id:"keep_ova",
      initializeOnMount: true,
      label: "Keep Image in Object Storage upon completion.",
      checked: keepOva,
      onChange: (value) => {setKeepOva(value)},
    },
  ]
});

export default createSchema;